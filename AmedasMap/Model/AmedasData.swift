//
//  AmedasData.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/01.
//

import Foundation

enum AmedasElement {
    case temperature, precipitation, wind
    
    func next() -> Self {
        switch self {
        case .temperature:
            return .precipitation
        case .precipitation:
            return .wind
        case .wind:
            return .temperature
        }
    }
}

struct AmedasData: CustomStringConvertible {
    let pointID: String
    let temperature: Double?
    let precipitation1h: Double?
    let precipitation10m: Double?
    let windDirection: Int?
    let windSpeed: Double?
    
    func hasValidData(for element: AmedasElement) -> Bool {
        switch element {
        case .temperature:
            return temperature != nil
        case .precipitation:
            return precipitation1h != nil
        case .wind:
            guard let windDirection = windDirection, windDirection >= 0, windDirection < directionText.count else { return false }
            return windSpeed != nil
        }
    }

    var temperatureText: String {
        guard let temperature = temperature else { return "-" }
        return String(format: "%.1f℃", temperature)
    }

    var precipitationText: String {
        guard let precipitation = precipitation1h else { return "-" }
        return String(format: "%.1fmm/h", precipitation)
    }
    
    let directionText = [ "", "北北東", "北東", "東北東", "東",
                          "東南東", "南東", "南南東", "南",
                          "南南西", "南西", "西南西", "西",
                          "西北西", "北西", "北北西", "北" ]
    var windText: String {
        guard let windDir = windDirection, windDir >= 0, windDir < directionText.count,
              let windSpeed = windSpeed else { return "-" }
        return String(format: "%@ %.1fm/s", directionText[windDir], windSpeed)
    }
    
    var description: String {
        var ary: [String] = []
        ary.append(pointID)
        ary.append("temp:" + temperatureText)
        ary.append("prec:" + precipitationText)
        ary.append("wind:" + windText)
        return ary.joined(separator: ", ")
    }
}

struct AmedasDataLoader {
    struct AmedasReult {
        let date: Date
        let data: [AmedasData]
    }
    
    enum LoadError: Error {
        case wrongUrl
        case httpError
        case parseError
    }
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZoneJST
        return dateFormatter
    }()
    
    // 最新データの時刻を取得
    func load(completion: @escaping (Result<AmedasReult, LoadError>) -> Void) {
        guard let url = URL(string: API.amedasLatestTime) else {
            completion(.failure(.wrongUrl))
            return
        }

        LOG("load: " + url.absoluteString)
        let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard let data = data, error == nil else {
                LOG("http error.")
                completion(.failure(.httpError))
                return
            }
            
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = TimeZoneJST
            
            guard let text = String(data: data, encoding: .utf8),
                  let date = formatter.date(from: text) else {
                LOG("date parse error. \(String(data: data, encoding: .utf8) ?? "")")
                completion(.failure(.parseError))
                return
            }
            
            LOG("parsed date: \(date)")
            load(date: date, completion: completion)
        }
        task.resume()
    }
  
    // 指定時刻の観測値一覧を取得
    private func load(date: Date, completion: @escaping (Result<AmedasReult, LoadError>) -> Void) {
        let urlString = String(format: API.amedasMapData, dateFormatter.string(from: date))
        guard let url = URL(string: urlString) else {
            completion(.failure(.wrongUrl))
            return
        }

        LOG("load: " + urlString)
        let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard let data = data, error == nil else {
                LOG("http error.")
                completion(.failure(.httpError))
                return
            }
            
            guard let list = parseAmedasData(data: data) else {
                LOG("json parse error.")
                completion(.failure(.parseError))
                return
            }
            
            completion(.success(AmedasReult(date: date, data: list)))
        }
        task.resume()
    }
    
    func parseAmedasData(data: Data) -> [AmedasData]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            return nil
        }

        var list: [AmedasData] = []
        for item in json {
            let obs = AmedasData(pointID: item.key,
                                 temperature: parseDouble(item.value["temp"]),
                                 precipitation1h: parseDouble(item.value["precipitation1h"]),
                                 precipitation10m: parseDouble(item.value["precipitation10m"]),
                                 windDirection: parseInt(item.value["windDirection"]),
                                 windSpeed: parseDouble(item.value["wind"]))
            list.append(obs)
        }
        return list
    }
    
    private func parseDouble(_ value: Any?) -> Double? {
        guard let val = value as? [Double], val.count == 2 else { return nil }
        if val[1] == 0 {
            return val[0]
        } else {
            return nil
        }
    }
    
    private func parseInt(_ value: Any?) -> Int? {
        guard let val = value as? [Int], val.count == 2 else { return nil }
        if val[1] == 0 {
            return val[0]
        } else {
            return nil
        }
    }
}
