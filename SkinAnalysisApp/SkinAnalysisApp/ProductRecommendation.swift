import Foundation

struct ProductRecommendation: Hashable, Identifiable {
    var id = UUID()
    let title: String
    let link: String
    let image: String
    let price: String
    let reviews: Int
    let rating: Float
}
