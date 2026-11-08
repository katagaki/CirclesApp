#if os(iOS) && !targetEnvironment(macCatalyst)
import AppIntents
import ORBiT

struct CirclesAppIntents: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [ORBiTAppIntents.self]
    }
}
#endif
