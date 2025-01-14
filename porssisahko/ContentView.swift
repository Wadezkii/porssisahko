import SwiftUI
import Foundation

// Define a model for the API response
struct PriceResponse: Codable {
    let price: Double
}

class APIService {
    func fetchPrice(completion: @escaping (Double?) -> Void) {
        let currentDay = Date()
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDay = dayFormatter.string(from: currentDay)

        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "HH"
        let formattedHour = hourFormatter.string(from: currentDay)

        guard let url = URL(string: "https://api.porssisahko.net/v1/price.json?date=\(formattedDay)&hour=\(formattedHour)") else {
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            // Check for errors
            if let error = error {
                print("Error fetching price: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // Check for valid response and data
            guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print("Invalid response or data")
                completion(nil)
                return
            }

            // Decode the JSON data into the appropriate structure
            do {
                let priceResponse = try JSONDecoder().decode(PriceResponse.self, from: data)
                completion(priceResponse.price) // Return the price value
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
                completion(nil)
            }
        }

        task.resume()
    }
}

struct ContentView: View {
    @State private var electricityPrice: String = "Loading..."
    @State private var currentDate: String = ""

    var body: some View {
        VStack {
            Text(currentDate)
                .font(.headline)
                .padding(.bottom, 20)

            Text("Electricity Price:")
                .font(.title2)

            Text(electricityPrice)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.tint)
                .padding()

            Spacer()
        }
        .padding()
        .onAppear {
            fetchData()
        }
    }

    private func fetchData() {
        let currentDay = Date()
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        currentDate = "Date: \(dayFormatter.string(from: currentDay))"

        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "HH"
        _ = hourFormatter.string(from: currentDay)

        let apiService = APIService()
        apiService.fetchPrice { price in
            DispatchQueue.main.async {
                if let price = price {
                    electricityPrice = "\(price) cents/kWh"
                } else {
                    electricityPrice = "Failed to load"
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
