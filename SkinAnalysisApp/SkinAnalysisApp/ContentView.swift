import SwiftUI

struct ContentView: View {
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    @EnvironmentObject var viewModel: ContentViewModel

    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .padding()
            }

            Button(action: {
                isImagePickerPresented.toggle()
            }) {
                Text("Take a Photo")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage)
            }

            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }

            if let analysisResult = viewModel.analysisResult {
                Text(analysisResult)
                    .padding()

                if let recommendations = viewModel.recommendations {
                    ForEach(recommendations, id: \.self.id) { product in
                        VStack(alignment: .leading) {
                            Text(product.title)
                            Text("Price: \(product.price)")
                            Text("Rating: \(product.rating, specifier: "%.1f")")
                            Text("Reviews: \(product.reviews)")
                            Link("Buy Now", destination: URL(string: product.link)!)
                                .foregroundColor(.blue)
                        }
                        .padding()
                    }
                }

                Button(action: {
                    viewModel.shareResults()
                }) {
                    Text("Share Results")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .padding()
        .onChange(of: selectedImage) { newImage in
            if let newImage = newImage {
                viewModel.uploadImage(image: newImage)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ContentViewModel())
    }
}
