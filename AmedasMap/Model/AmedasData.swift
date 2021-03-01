//
//  AmedasData.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/01.
//

import Foundation

struct AmedasData: CustomStringConvertible {
    let pointID: String
    let temperature: Double?
    let precipitation1h: Double?
    let precipitation10m: Double?
    let windDirection: Int?
    let windSpeed: Double?
    
    var description: String {
        var ary: [String] = []
        ary.append(pointID)
        if let temperature = temperature {
            ary.append(String(format: "temp:%.1f℃", temperature))
        }
        if let precipitation1h = precipitation1h {
            ary.append(String(format: "prec:%.1fmm/h", precipitation1h))
        }
        if let windDir = windDirection, let windSpeed = windSpeed {
            ary.append(String(format: "wind:%d %.1fm/s", windDir, windSpeed))
        }
        return ary.joined(separator: ", ")
    }
}

struct AmedasDataLoader {
    enum LoadError: Error {
        case wrongUrl
        case httpError
        case parseError
    }
    
    static let timeZone = TimeZone(identifier: "JST")
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = Self.timeZone
        return dateFormatter
    }()
    
    // 最新データの時刻を取得
    func load(completion: @escaping (Result<[AmedasData], LoadError>) -> Void) {
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
            formatter.timeZone = Self.timeZone
            
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
    private func load(date: Date, completion: @escaping (Result<[AmedasData], LoadError>) -> Void) {
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
            
            completion(.success(list))
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
