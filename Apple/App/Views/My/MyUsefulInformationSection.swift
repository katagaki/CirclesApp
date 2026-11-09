import SwiftUI

private let webCatalogJPURL = "https://webcatalog.circle.ms"
private let webCatalogENURL = "https://int.webcatalog.circle.ms"
private let corporateBoothsJPURL = "https://webcatalog.circle.ms/booth/list"
private let corporateBoothsENURL = "https://int.webcatalog.circle.ms/booth"
private let comiketURL = "https://comiket.co.jp"
private let officialXJPURL = "https://x.com/comiketofficial"
private let officialXENURL = "https://x.com/comiket_intl"
private let bigSightMapJPURL = "https://www.bigsight.jp/visitor/floormap/"
private let bigSightMapENURL = "https://www.bigsight.jp/english/visitor/floormap/"

struct MyUsefulInformationSection: View {

    var isJapanese: Bool {
        Locale.current.language.languageCode == .japanese
    }

    var body: some View {
        Section {
            MyLinkRow(url: isJapanese ? webCatalogJPURL : webCatalogENURL,
                      title: "More.UsefulResources.WebCatalog", image: "ListIcon.WebCatalog")
            MyLinkRow(url: isJapanese ? corporateBoothsJPURL : corporateBoothsENURL,
                      title: "More.UsefulResources.CorporateBooths", image: "ListIcon.WebCatalog")
            MyLinkRow(url: comiketURL,
                      title: "More.UsefulResources.Comiket", image: "ListIcon.Comiket")
            MyLinkRow(url: isJapanese ? officialXJPURL : officialXENURL,
                      title: "More.UsefulResources.OfficialX", image: "ListIcon.Comiket")
            MyLinkRow(url: isJapanese ? bigSightMapJPURL : bigSightMapENURL,
                      title: "More.UsefulResources.BigSightMap", image: "ListIcon.BigSight")
        } header: {
            Text("More.UsefulResources")
        }
    }
}
