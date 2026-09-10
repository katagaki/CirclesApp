import Foundation

/// The display name a guest is given on the way into a room.
///
/// A guest never signs in, so there is no circle.ms nickname to borrow and no good
/// moment to ask for one — they have scanned a code and want to be in the list. A name
/// is minted instead, and kept, so the same phone is the same member across relaunches
/// and across rooms. `actorPID` is what actually distinguishes members; this is only
/// what the members list and the avatar initial read.
///
/// Mirrored by `SharedBuysGuestName.kt`. The two lists are kept identical so a room
/// looks the same whichever platform a member is on, but nothing breaks if they drift:
/// the name travels in the log as text.
public enum SharedBuysGuestName {

    /// Given names only, so a name plus its discriminator stays short enough to sit in
    /// a members row and on a Live Activity.
    static let names = [
        "Airi", "Akane", "Ako", "Aris", "Aru", "Asuna", "Atsuko", "Ayane", "Azusa",
        "Cherino", "Chiaki", "Chihiro", "Chinatsu", "Chise", "Eimi", "Fubuki", "Fuuka",
        "Hanae", "Hanako", "Hare", "Haruka", "Haruna", "Hasumi", "Hibiki", "Hifumi",
        "Himari", "Hina", "Hinata", "Hiyori", "Hoshino", "Iori", "Iroha", "Izumi",
        "Junko", "Juri", "Kaede", "Kaho", "Kanna", "Kanoe", "Karin", "Kayoko", "Kazusa",
        "Kei", "Kirara", "Kirino", "Koharu", "Kokona", "Kotama", "Kotori", "Maki",
        "Mari", "Marina", "Mashiro", "Megu", "Michiru", "Midori", "Mika", "Miku",
        "Mimori", "Mine", "Misaki", "Miyako", "Miyu", "Moe", "Momoi", "Mutsuki",
        "Nagisa", "Natsu", "Neru", "Noa", "Nonomi", "Pina", "Reisa", "Rio", "Saki",
        "Saori", "Saya", "Sena", "Serika", "Serina", "Shiroko", "Shizuko", "Shun",
        "Sumire", "Suzumi", "Toki", "Tomoe", "Tsubaki", "Tsukuyo", "Ui", "Utaha",
        "Wakamo", "Yoshimi", "Yuuka", "Yuzu"
    ]

    /// A fresh name, as `Kazusa#1234`.
    ///
    /// Zero-padded so the discriminator is always four digits: an unpadded
    /// `Int.random(in: 0...9999)` would render `Kazusa#7` about one time in a thousand,
    /// and the point of the suffix is that two guests who draw the same name are still
    /// told apart at a glance.
    public static func generate() -> String {
        let name = names.randomElement() ?? "Sensei"
        return "\(name)#\(String(format: "%04d", Int.random(in: 0...9999)))"
    }
}
