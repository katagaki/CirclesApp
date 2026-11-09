import Foundation

enum MockData {

    static let names = [
        "ねこまんま堂", "星屑ラボ", "夜更かし工房", "空色ドロップス", "鉄道少年団", "あおぞら書房",
        "Studio Kaleido", "ふわふわ同盟", "月見草", "ピクセル茶屋", "雨宿り本舗", "Cosmic Tofu",
        "まどろみ舎", "灯台守", "スパイス研究会", "Neon Garden", "かもめ便", "紙ひこうき",
        "Quiet Arcade", "モノクロ画報", "ゆるふわ探検隊", "Paper Moon", "うみねこ商会", "白昼夢",
        "Retro Signal", "こんぺいとう", "朝凪", "Blue Hour", "しろくま印", "迷子の地図",
        "Velvet Static", "ことり書店", "雪見だいふく", "Hyper Picnic", "蒸気機関", "くじら座",
        "Lantern Press", "おやつ時間", "銀河鉄道", "Mint Arcade"
    ]

    static let authors = [
        "みけ", "Aoi", "ほしの", "Rin", "たけし", "Mika", "Sora", "ゆき", "Kenji", "はる",
        "Nao", "つばさ", "Yuu", "ちひろ", "Ren", "Hana", "かえで", "Leo", "まこと", "Emi"
    ]

    static let genres = ["Original", "Games", "Anime", "Comics", "Tech", "Music", "Photography", "Travel", "Food", "Design"]

    static let circles: [MockCircle] = (0..<names.count).map { index in
        let hall = Hall.allCases[index % 3 == 0 ? 0 : (index % 3 == 1 ? 1 : (index % 2 == 0 ? 3 : 5))]
        let blocks = hall.blocks
        let blockIndex = (index * 7) % blocks.count
        return MockCircle(
            id: 1000 + index,
            name: names[index],
            author: authors[index % authors.count],
            genre: genres[(index * 3) % genres.count],
            hall: hall,
            block: blocks[blockIndex],
            space: (index * 11) % 48 + 1,
            half: index % 2 == 0 ? "a" : "b",
            day: index % 2 + 1,
            hue: Double((index * 37) % 100) / 100.0,
            blockIndex: blockIndex,
            slotIndex: (index * 5) % 16
        )
    }

    static let initialFavorites: [Int: FavoriteColor] = [
        1000: .orange, 1003: .orange, 1006: .pink, 1009: .yellow, 1012: .green,
        1015: .cyan, 1018: .orange, 1021: .purple, 1024: .pink, 1027: .green,
        1001: .blue, 1004: .red
    ]

    static let initialBuys: [BuyItem] = [
        BuyItem(id: 1, circleID: 1000, title: "新刊セット", price: 1500, isBought: true, assignee: nil),
        BuyItem(id: 2, circleID: 1003, title: "アクリルキーホルダー", price: 800, isBought: false, assignee: nil),
        BuyItem(id: 3, circleID: 1006, title: "画集 Vol.3", price: 2000, isBought: false, assignee: "Aoi"),
        BuyItem(id: 4, circleID: 1009, title: "ポストカード", price: 300, isBought: false, assignee: nil),
        BuyItem(id: 5, circleID: 1012, title: "既刊まとめ", price: 1200, isBought: true, assignee: "Mika"),
        BuyItem(id: 6, circleID: 1015, title: "缶バッジ", price: 400, isBought: false, assignee: "Aoi")
    ]

    static let members: [SharedMember] = [
        SharedMember(id: "me", name: "You", hue: 0.58, location: "東A-12", progress: 0.4),
        SharedMember(id: "aoi", name: "Aoi", hue: 0.92, location: "東ア-03", progress: 0.65),
        SharedMember(id: "mika", name: "Mika", hue: 0.33, location: "西あ-21", progress: 0.2)
    ]

    static func circle(_ id: Int) -> MockCircle? {
        circles.first { $0.id == id }
    }
}
