//
//  SharedBuysBluetooth.swift
//  CiRCLES
//

import CoreBluetooth
import Foundation

enum BluetoothEvent: Sendable {
    case peerCount(Int)
    /// A peer finished the handshake, carrying the digest it advertised if we scanned it.
    case peerVerified(Data?)
    case payload(Data)
    case unavailable(String)
}

@MainActor
final class SharedBuysBluetooth: NSObject {

    private var peripheralManager: CBPeripheralManager?
    private var centralManager: CBCentralManager?
    private var outbox: CBMutableCharacteristic?

    private var connected: [UUID: CBPeripheral] = [:]
    private var inboxes: [UUID: CBCharacteristic] = [:]
    private var subscribers: [CBCentral] = []
    private var reassemblers: [UUID: SharedBuysFraming.Reassembler] = [:]
    private var centralReassemblers: [UUID: SharedBuysFraming.Reassembler] = [:]
    private var verifiedPeripherals: Set<UUID> = []
    private var verifiedCentrals: Set<UUID> = []
    private var rejectedUntil: [UUID: Date] = [:]
    private var pendingNotifies: [(frame: Data, centrals: [CBCentral])] = []
    private var messageCounter: UInt8 = 0
    private var peerDigests: [UUID: Data] = [:]
    private var advertisedWindow: Int?
    private var refreshTask: Task<Void, Never>?

    private var sessionKey: Data?
    private var digest: Data = Data(repeating: 0, count: 4)
    private var onEvent: ((BluetoothEvent) -> Void)?

    var peerCount: Int { verifiedPeripherals.count + verifiedCentrals.count }

    private var verifiedSubscribers: [CBCentral] {
        subscribers.filter { verifiedCentrals.contains($0.identifier) }
    }

    func start(sessionKey: Data, digest: Data, onEvent: @escaping (BluetoothEvent) -> Void) {
        self.sessionKey = sessionKey
        self.digest = digest
        self.onEvent = onEvent
        if peripheralManager == nil {
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        }
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
        advertise()
        scan()
        startRefreshing()
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
        advertisedWindow = nil
        peripheralManager?.stopAdvertising()
        centralManager?.stopScan()
        for peripheral in connected.values {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connected.removeAll()
        inboxes.removeAll()
        subscribers.removeAll()
        reassemblers.removeAll()
        centralReassemblers.removeAll()
        verifiedPeripherals.removeAll()
        verifiedCentrals.removeAll()
        rejectedUntil.removeAll()
        pendingNotifies.removeAll()
        peerDigests.removeAll()
        sessionKey = nil
        onEvent = nil
    }

    func update(digest: Data) {
        guard self.digest != digest else { return }
        self.digest = digest
        advertise()
    }

    func send(_ payload: Data) {
        messageCounter &+= 1
        let frames = SharedBuysFraming.chunks(of: payload, messageID: messageCounter)
        for frame in frames {
            notify(frame, to: verifiedSubscribers)
            for identifier in verifiedPeripherals {
                guard let peripheral = connected[identifier], let inbox = inboxes[identifier] else { continue }
                peripheral.writeValue(frame, for: inbox, type: .withoutResponse)
            }
        }
    }

    private func advertise() {
        guard let peripheralManager, peripheralManager.state == .poweredOn, let sessionKey else { return }
        // CoreBluetooth only lets a peripheral advertise service UUIDs and a local name,
        // so the room tag and digest ride in the name; Android puts the same bytes in
        // its scan response as service data, and both sides read either field.
        advertisedWindow = SharedBuysProfile.window(at: .now)
        peripheralManager.stopAdvertising()
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [SharedBuysProfile.serviceUUID],
            CBAdvertisementDataLocalNameKey: SharedBuysProfile.localName(
                sessionKey: sessionKey,
                digest: digest
            )
        ])
    }

    /// The advertised tag is only valid for its window, so it has to be reissued before
    /// the window turns over, or peers stop recognising us as part of the room.
    private func startRefreshing() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard let self, self.sessionKey != nil else { return }
                if self.advertisedWindow != SharedBuysProfile.window(at: .now) { self.advertise() }
            }
        }
    }

    private func scan() {
        guard let centralManager, centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(
            withServices: [SharedBuysProfile.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    private func publishService() {
        guard let peripheralManager, peripheralManager.state == .poweredOn else { return }
        let inbox = CBMutableCharacteristic(
            type: SharedBuysProfile.inboxUUID,
            properties: [.writeWithoutResponse],
            value: nil,
            permissions: [.writeable]
        )
        let outbox = CBMutableCharacteristic(
            type: SharedBuysProfile.outboxUUID,
            properties: [.notify],
            value: nil,
            permissions: [.readable]
        )
        let service = CBMutableService(type: SharedBuysProfile.serviceUUID, primary: true)
        service.characteristics = [inbox, outbox]
        self.outbox = outbox
        peripheralManager.removeAllServices()
        peripheralManager.add(service)
    }

    private func shouldConnect(to peripheral: CBPeripheral) -> Bool {
        guard sessionKey != nil, connected[peripheral.identifier] == nil else { return false }
        if let until = rejectedUntil[peripheral.identifier], until > .now { return false }
        return true
    }

    private func reject(_ peripheral: CBPeripheral) {
        rejectedUntil[peripheral.identifier] = .now.addingTimeInterval(60.0)
        centralManager?.cancelPeripheralConnection(peripheral)
    }

    private func notify(_ frame: Data, to centrals: [CBCentral]) {
        guard let outbox, !centrals.isEmpty else { return }
        guard pendingNotifies.isEmpty else {
            pendingNotifies.append((frame, centrals))
            return
        }
        if peripheralManager?.updateValue(frame, for: outbox, onSubscribedCentrals: centrals) != true {
            pendingNotifies.append((frame, centrals))
        }
    }

    private func flushNotifies() {
        guard let outbox else { return }
        while let next = pendingNotifies.first {
            guard peripheralManager?.updateValue(
                next.frame,
                for: outbox,
                onSubscribedCentrals: next.centrals
            ) == true else { return }
            pendingNotifies.removeFirst()
        }
    }

    private func deliver(_ frame: Data, from identifier: UUID) {
        var reassembler = reassemblers[identifier] ?? SharedBuysFraming.Reassembler()
        let payload = reassembler.accept(frame)
        reassemblers[identifier] = reassembler
        if let payload { onEvent?(.payload(payload)) }
    }

    private func deliverFromPeripheral(_ frame: Data, from identifier: UUID) {
        var reassembler = centralReassemblers[identifier] ?? SharedBuysFraming.Reassembler()
        let payload = reassembler.accept(frame)
        centralReassemblers[identifier] = reassembler
        if let payload { onEvent?(.payload(payload)) }
    }

    private func announcePeers() {
        onEvent?(.peerCount(peerCount))
    }
}

extension SharedBuysBluetooth: @preconcurrency CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            publishService()
            advertise()
        case .unauthorized:
            onEvent?(.unavailable("bluetooth not permitted"))
        case .poweredOff:
            onEvent?(.unavailable("bluetooth off"))
        default:
            break
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        if !subscribers.contains(where: { $0.identifier == central.identifier }) {
            subscribers.append(central)
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        subscribers.removeAll { $0.identifier == central.identifier }
        verifiedCentrals.remove(central.identifier)
        reassemblers[central.identifier] = nil
        announcePeers()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            guard let value = request.value else { continue }
            let identifier = request.central.identifier
            if SharedBuysProfile.handshakeTag(in: value) != nil {
                guard let sessionKey,
                      SharedBuysProfile.accepts(handshake: value, sessionKey: sessionKey) else { continue }
                verifiedCentrals.insert(identifier)
                notify(SharedBuysProfile.handshake(sessionKey: sessionKey), to: [request.central])
                announcePeers()
                // We never scanned this one, so its digest is unknown.
                onEvent?(.peerVerified(nil))
                continue
            }
            guard verifiedCentrals.contains(identifier) else { continue }
            deliver(value, from: identifier)
        }
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        flushNotifies()
    }
}

extension SharedBuysBluetooth: @preconcurrency CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn { scan() }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard shouldConnect(to: peripheral) else { return }
        let serviceData = (advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data])?[
            SharedBuysProfile.serviceUUID
        ]
        // A peer that carries no room bytes is not necessarily a stranger — an iOS app
        // in the background cannot advertise a local name — so it still gets a chance at
        // the handshake. One that carries the wrong room is a stranger, and connecting
        // to it could only end in a failed handshake.
        if let advertisement = SharedBuysProfile.advertisement(
            serviceData: serviceData,
            localName: advertisementData[CBAdvertisementDataLocalNameKey] as? String
        ) {
            guard let sessionKey,
                  SharedBuysProfile.accepts(advertisement: advertisement, sessionKey: sessionKey)
            else {
                rejectedUntil[peripheral.identifier] = .now.addingTimeInterval(60.0)
                return
            }
            peerDigests[peripheral.identifier] = SharedBuysProfile.digest(in: advertisement)
        }
        connected[peripheral.identifier] = peripheral
        peripheral.delegate = self
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([SharedBuysProfile.serviceUUID])
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        connected[peripheral.identifier] = nil
        inboxes[peripheral.identifier] = nil
        peerDigests[peripheral.identifier] = nil
        reassemblers[peripheral.identifier] = nil
        centralReassemblers[peripheral.identifier] = nil
        verifiedPeripherals.remove(peripheral.identifier)
        announcePeers()
    }
}

extension SharedBuysBluetooth: @preconcurrency CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == SharedBuysProfile.serviceUUID })
        else { return }
        peripheral.discoverCharacteristics(
            [SharedBuysProfile.inboxUUID, SharedBuysProfile.outboxUUID],
            for: service
        )
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: (any Error)?
    ) {
        if let inbox = service.characteristics?.first(where: { $0.uuid == SharedBuysProfile.inboxUUID }) {
            inboxes[peripheral.identifier] = inbox
        }
        guard let outbox = service.characteristics?.first(where: { $0.uuid == SharedBuysProfile.outboxUUID })
        else {
            reject(peripheral)
            return
        }
        peripheral.setNotifyValue(true, for: outbox)
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        guard characteristic.uuid == SharedBuysProfile.outboxUUID, characteristic.isNotifying else { return }
        guard let sessionKey, let inbox = inboxes[peripheral.identifier] else { return }
        peripheral.writeValue(
            SharedBuysProfile.handshake(sessionKey: sessionKey),
            for: inbox,
            type: .withoutResponse
        )
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        guard let value = characteristic.value else { return }
        if SharedBuysProfile.handshakeTag(in: value) != nil {
            guard let sessionKey,
                  SharedBuysProfile.accepts(handshake: value, sessionKey: sessionKey) else {
                reject(peripheral)
                return
            }
            verifiedPeripherals.insert(peripheral.identifier)
            announcePeers()
            onEvent?(.peerVerified(peerDigests[peripheral.identifier]))
            return
        }
        guard verifiedPeripherals.contains(peripheral.identifier) else { return }
        deliverFromPeripheral(value, from: peripheral.identifier)
    }
}
