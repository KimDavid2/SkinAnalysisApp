import SwiftUI
import Combine

class ContentViewModel: ObservableObject {
    @Published var analysisResult: String?
    @Published var recommendations: [ProductRecommendation]?
    @Published var isLoading = false
    
    func uploadImage(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        isLoading = true

        var request = URLRequest(url: URL(string: "http://localhost:5000/upload")!)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        data.append(imageData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }

            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.analysisResult = "Error: \(error?.localizedDescription ?? "Unknown error")"
                }
                return
            }

            if let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let results = responseJSON["results"] as? String,
               let recommendationsData = responseJSON["recommendations"] as? [[String: Any]] {

                let recommendations: [ProductRecommendation] = recommendationsData.compactMap { dict in
                    guard let title = dict["title"] as? String,
                          let link = dict["link"] as? String,
                          let image = dict["image"] as? String,
                          let price = dict["price"] as? String,
                          let reviews = dict["reviews"] as? Int,
                          let rating = dict["rating"] as? Float else { return nil }
                    return ProductRecommendation(title: title, link: link, image: image, price: price, reviews: reviews, rating: rating)
                }

                DispatchQueue.main.async {
                    self.analysisResult = results
                    self.recommendations = recommendations
                }
            } else {
                DispatchQueue.main.async {
                    self.analysisResult = "Error: Invalid response"
                }
            }
        }.resume()
    }

    func shareResults() {
        guard let analysisResult = analysisResult, let recommendations = recommendations else { return }

        let items = ["""
        피부 상태: \(analysisResult)
        
        추천 제품:
        \(recommendations.map { "\($0.title) - \($0.price)" }.joined(separator: "\n"))
        """]
        
        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let topController = scene.windows.first?.rootViewController {
                topController.present(activityController, animated: true)
            }
        }
    }
}
