//
//  SharedBuysBluetooth.swift
//  CiRCLES
//

import CoreBluetooth
import Foundation

enum BluetoothEvent: Sendable {
    case peerCount(Int)
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
    private var centralReassembler = SharedBuysFraming.Reassembler()
    private var seenDigests: [UUID: Data] = [:]
    private var messageCounter: UInt8 = 0

    private var sessionKey: Data?
    private var digest: Data = Data(repeating: 0, count: 4)
    private var onEvent: ((BluetoothEvent) -> Void)?

    var peerCount: Int { connected.count + subscribers.count }

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
    }

    func stop() {
        peripheralManager?.stopAdvertising()
        centralManager?.stopScan()
        for peripheral in connected.values {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connected.removeAll()
        inboxes.removeAll()
        subscribers.removeAll()
        seenDigests.removeAll()
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
            if let outbox, !subscribers.isEmpty {
                peripheralManager?.updateValue(frame, for: outbox, onSubscribedCentrals: subscribers)
            }
            for peripheral in connected.values {
                guard let inbox = inboxes[peripheral.identifier] else { continue }
                peripheral.writeValue(frame, for: inbox, type: .withoutResponse)
            }
        }
    }

    private func advertise() {
        guard let peripheralManager, peripheralManager.state == .poweredOn, let sessionKey else { return }
        peripheralManager.stopAdvertising()
        var payload = SharedBuysProfile.sessionTag(sessionKey: sessionKey)
        payload.append(digest)
        payload.append(UInt8(min(peerCount, 255)))
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [SharedBuysProfile.serviceUUID],
            CBAdvertisementDataServiceDataKey: [SharedBuysProfile.serviceUUID: payload]
        ])
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

    private func shouldConnect(to peripheral: CBPeripheral, advertisement: [String: Any]) -> Bool {
        guard let sessionKey else { return false }
        guard let serviceData = advertisement[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data],
              let payload = serviceData[SharedBuysProfile.serviceUUID], payload.count >= 6 else {
            return false
        }
        let tag = payload.prefix(2)
        guard SharedBuysProfile.acceptedTags(sessionKey: sessionKey).contains(Data(tag)) else { return false }
        let theirDigest = Data(payload.dropFirst(2).prefix(4))
        if theirDigest == digest, seenDigests[peripheral.identifier] == theirDigest {
            return false
        }
        seenDigests[peripheral.identifier] = theirDigest
        return theirDigest != digest || connected[peripheral.identifier] == nil
    }

    private func deliver(_ frame: Data, from identifier: UUID) {
        var reassembler = reassemblers[identifier] ?? SharedBuysFraming.Reassembler()
        let payload = reassembler.accept(frame)
        reassemblers[identifier] = reassembler
        if let payload { onEvent?(.payload(payload)) }
    }

    private func deliverFromPeripheral(_ frame: Data) {
        if let payload = centralReassembler.accept(frame) {
            onEvent?(.payload(payload))
        }
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
        announcePeers()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        subscribers.removeAll { $0.identifier == central.identifier }
        announcePeers()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            guard let value = request.value else { continue }
            deliver(value, from: request.central.identifier)
        }
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
        guard shouldConnect(to: peripheral, advertisement: advertisementData) else { return }
        guard connected[peripheral.identifier] == nil else { return }
        connected[peripheral.identifier] = peripheral
        peripheral.delegate = self
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([SharedBuysProfile.serviceUUID])
        announcePeers()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        connected[peripheral.identifier] = nil
        inboxes[peripheral.identifier] = nil
        reassemblers[peripheral.identifier] = nil
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
        if let outbox = service.characteristics?.first(where: { $0.uuid == SharedBuysProfile.outboxUUID }) {
            peripheral.setNotifyValue(true, for: outbox)
        }
        if let inbox = service.characteristics?.first(where: { $0.uuid == SharedBuysProfile.inboxUUID }) {
            inboxes[peripheral.identifier] = inbox
        }
        announcePeers()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        guard let value = characteristic.value else { return }
        deliverFromPeripheral(value)
    }
}
