import SwiftUI
import Foundation

struct PriceResponse: Codable {
    let price: Double
}

class APIService {
    func fetchPrice(for date: String, hour: String, completion: @escaping (Double?) -> Void) {
        guard let url = URL(string: "https://api.porssisahko.net/v1/price.json?date=\(date)&hour=\(hour)") else {
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
    @State private var currentPrice: Double?
    @State private var upcomingPrices: [String: Double] = [:]
    @State private var currentDate: String = ""
    @State private var isLoading: Bool = true

    var body: some View {
        VStack {
            Text(currentDate)
                .font(.headline)
                .padding(.bottom, 20)

            // Current Price
            Text("Current Electricity Price:")
                .font(.title2)

            if let price = currentPrice {
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

            // Upcoming Prices
            Text("Upcoming Prices:")
                .font(.title2)
                .padding(.top, 20)

            if isLoading {
                ProgressView()
                    .padding()
            } else {
                List {
                    ForEach(upcomingPrices.sorted(by: { $0.key < $1.key }), id: \.key) { hour, price in
                        HStack {
                            Text("\(hour):00")
                                .font(.subheadline)
                            Spacer()
                            Text(formatPrice(price))
                                .font(.subheadline)
                                .foregroundColor(getColor(for: price))
                        }
                    }
                }
                .listStyle(PlainListStyle())
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

        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "HH"
        let currentHour = hourFormatter.string(from: currentDay)

        let apiService = APIService()

        // Fetch current price
        apiService.fetchPrice(for: dayFormatter.string(from: currentDay), hour: currentHour) { price in
            DispatchQueue.main.async {
                currentPrice = price
            }
        }

        // Fetch upcoming prices for the rest of the day and the next day
        let calendar = Calendar.current
        let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
        let hours = (Int(currentHour)!..<24).map { String(format: "%02d", $0) } // Remaining hours today
        let nextDayHours = (0..<24).map { String(format: "%02d", $0) } // All hours tomorrow

        let allHours = hours + nextDayHours
        let allDates = Array(repeating: dayFormatter.string(from: currentDay), count: hours.count) +
                       Array(repeating: dayFormatter.string(from: nextDay), count: nextDayHours.count)

        for (date, hour) in zip(allDates, allHours) {
            apiService.fetchPrice(for: date, hour: hour) { price in
                DispatchQueue.main.async {
                    upcomingPrices["\(date) \(hour):00"] = price
                    if upcomingPrices.count == allHours.count {
                        isLoading = false
                    }
                }
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
