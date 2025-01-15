import SwiftUI
import Foundation

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
            if let error = error {
                print("Error fetching price: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print("Invalid response or data")
                completion(nil)
                return
            }
            do {
                let priceResponse = try JSONDecoder().decode(PriceResponse.self, from: data)
                completion(priceResponse.price)
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
                completion(nil)
            }
        }

        task.resume()
    }
}

struct ContentView: View {
    @State private var priceValue: Double?
    @State private var currentDate: String = ""

    var body: some View {
        VStack {
            Text(currentDate)
                .font(.headline)
                .padding(.bottom, 20)

            Text("Electricity Price:")
                .font(.title2)

            if let price = priceValue {
                Text(formatPrice(price))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(getColor(for: price))
                    .padding()
            } else {
                Text("Loading...")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .padding()
            }

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

        let apiService = APIService()
        apiService.fetchPrice { price in
            DispatchQueue.main.async {
                priceValue = price
            }
        }
    }

    private func getColor(for price: Double) -> Color {
        if price >= 0 && price < 5 {
            return .green
        } else if price >= 5 && price <= 30 {
            return .yellow
        } else {
            return .red
        }
    }

    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        formatter.numberStyle = .decimal
        return "\(formatter.string(from: NSNumber(value: price)) ?? "\(price)") cents/kWh"
    }
}

#Preview {
    ContentView()
}
