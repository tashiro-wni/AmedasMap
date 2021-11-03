//
//  AmedasData.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/01.
//

import Foundation

enum AmedasElement: CaseIterable {
    case temperature, precipitation, wind, sun, humidity
}

// MARK: - AmedasData
struct AmedasData: Hashable, CustomStringConvertible {
    let id = UUID()
    let pointID: String
    let time: TimeInterval
    let temperature: Double?
    let precipitation1h: Double?
    let precipitation10m: Double?
    let windDirection: Int?
    let windSpeed: Double?
    let sun1h: Double?
    let humidity: Double?

    var is0min: Bool {  // 00分
        Int(time).isMultiple(of: 3600)
    }
    let invalidText = "-"
    private let directionText = [ "静穏", "北北東", "北東", "東北東", "東",
                                  "東南東", "南東", "南南東", "南",
                                  "南南西", "南西", "西南西", "西",
                                  "西北西", "北西", "北北西", "北" ]

    func hasValidData(for element: AmedasElement) -> Bool {
        switch element {
        case .temperature:
            return temperature != nil
        case .precipitation:
            guard let precipitation1h = precipitation1h else { return false }
            return precipitation1h > 0
        case .wind:
            guard let windDirection = windDirection, windDirection >= 0, windDirection < directionText.count else { return false }
            return windSpeed != nil
        case .sun:
            return sun1h != nil
        case .humidity:
            return humidity != nil
        }
    }

    func text(for element: AmedasElement) -> String {
        switch element {
        case .temperature:
            return temperatureText
        case .precipitation:
            return precipitationText
        case .wind:
            return windText
        case .sun:
            return sunText
        case .humidity:
            return humidityText
        }
    }
    
    private var temperatureText: String {
        guard let temperature = temperature else { return invalidText }
        return String(format: "%.1f℃", temperature)
    }

    private var precipitationText: String {
        guard let precipitation = precipitation1h else { return invalidText }
        return String(format: "%.1fmm/h", precipitation)
    }

    private var windText: String {
        guard let windDir = windDirection, windDir >= 0, windDir < directionText.count,
              let windSpeed = windSpeed else { return invalidText }
        return String(format: "%@ %.1fm/s", directionText[windDir], windSpeed)
    }
    
    private var sunText: String {
        guard let sun1h = sun1h else { return invalidText }
        return String(format: "%.0fmin", sun1h * 60)
    }
    
    private var humidityText: String {
        guard let humidity = humidity else { return invalidText }
        return String(format: "%.0f%%", humidity)
    }

    var description: String {
        var ary: [String] = []
        ary.append(pointID)
        ary.append("time:\(time)")
        ary.append("temp:" + temperatureText)
        ary.append("prec:" + precipitationText)
        ary.append("wind:" + windText)
        ary.append("sun:" + sunText)
        ary.append("hum:" + humidityText)

        return ary.joined(separator: ", ")
    }
}

// MARK: - AmedasDataLoader
struct AmedasDataLoader {
    struct AmedasMapReult {
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
        dateFormatter.locale = LocalePOSIX
        dateFormatter.timeZone = TimeZoneJST
        return dateFormatter
    }()
    
    // 最新データの時刻を取得
//    func load(completion: @escaping (Result<AmedasMapReult, LoadError>) -> Void) {
//        guard let url = URL(string: API.amedasLatestTime) else {
//            completion(.failure(.wrongUrl))
//            return
//        }
//
//        LOG("load: " + url.absoluteString)
//        let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
//            guard let data = data, error == nil else {
//                LOG("http error.")
//                completion(.failure(.httpError))
//                return
//            }
//
//            let formatter = ISO8601DateFormatter()
//            formatter.timeZone = TimeZoneJST
//
//            guard let text = String(data: data, encoding: .utf8),
//                  let date = formatter.date(from: text) else {
//                LOG("date parse error. \(String(data: data, encoding: .utf8) ?? "")")
//                completion(.failure(.parseError))
//                return
//            }
//
//            LOG("parsed date: \(date)")
//            load(date: date, completion: completion)
//        }
//        task.resume()
//    }
  
    func load() async throws -> AmedasMapReult {
        guard let url = URL(string: API.amedasLatestTime) else {
            throw LoadError.wrongUrl
        }
        LOG("load: " + url.absoluteString)
        let (data, _) = try await URLSession.shared.data2(for: URLRequest(url: url))
        
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZoneJST
        
        guard let text = String(data: data, encoding: .utf8),
              let date = formatter.date(from: text) else {
                  throw LoadError.parseError
              }
        return try await load(date: date)
    }
    
    // 指定時刻の観測値一覧を取得
//    private func load(date: Date, completion: @escaping (Result<AmedasMapReult, LoadError>) -> Void) {
//        dateFormatter.dateFormat = "yyyyMMddHHmm"
//        let urlString = String(format: API.amedasMapData, dateFormatter.string(from: date))
//        guard let url = URL(string: urlString) else {
//            completion(.failure(.wrongUrl))
//            return
//        }
//
//        LOG("load: " + urlString)
//        let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
//            guard let data = data, error == nil else {
//                LOG("http error.")
//                completion(.failure(.httpError))
//                return
//            }
//
//            guard let list = parseAmedasMapData(data: data, date: date) else {
//                LOG("json parse error.")
//                completion(.failure(.parseError))
//                return
//            }
//
//            completion(.success(AmedasMapReult(date: date, data: list)))
//        }
//        task.resume()
//    }
    
    private func load(date: Date) async throws -> AmedasMapReult {
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        let urlString = String(format: API.amedasMapData, dateFormatter.string(from: date))
        guard let url = URL(string: urlString) else {
            throw LoadError.wrongUrl
        }
        LOG("load: " + urlString)
        let (data, _) = try await URLSession.shared.data2(for: URLRequest(url: url))
        guard let list = parseAmedasMapData(data: data, date: date) else {
            throw LoadError.parseError
        }
        return AmedasMapReult(date: date, data: list)
    }

    func parseAmedasMapData(data: Data, date: Date) -> [AmedasData]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            return nil
        }

        var list: [AmedasData] = []
        for item in json {
            let obs = AmedasData(pointID:          item.key,
                                 time:             date.timeIntervalSince1970,
                                 temperature:      parseDouble(item.value["temp"]),
                                 precipitation1h:  parseDouble(item.value["precipitation1h"]),
                                 precipitation10m: parseDouble(item.value["precipitation10m"]),
                                 windDirection:    parseInt(item.value["windDirection"]),
                                 windSpeed:        parseDouble(item.value["wind"]),
                                 sun1h:            parseDouble(item.value["sun1h"]),
                                 humidity:         parseDouble(item.value["humidity"]))
            list.append(obs)
        }
        return list
    }

    // 指定地点の時系列観測値(過去24時間分)を取得
//    func load(point: String, date: Date, completion: @escaping (Result<[AmedasData], LoadError>) -> Void) {
//        let tm0 = floor(date.timeIntervalSince1970 / 10800) * 10800
//        var allData: [AmedasData] = []
//        var loading = 0
//
//        for i in 0...8 {
//            let tm = tm0 - Double(10800 * i)
//            loading += 1
//            loadPointFile(point: point, date: Date(timeIntervalSince1970: tm)) { result in
//                loading -= 1
//                switch result {
//                case .failure:
//                    break
//                case .success(let list):
//                    allData.append(contentsOf: list)
//                }
//                if loading == 0 {
//                    if allData.isEmpty {
//                        completion(.failure(.parseError))
//                    } else {
//                        // 全ての読み込みが完了したら、時系列にsortして返す
//                        completion(.success(allData.sorted(by: {$0.time < $1.time})))
//                    }
//                }
//            }
//        }
//    }
    
    func load(point: String, date: Date) async throws -> [AmedasData] {
        let tm0 = floor(date.timeIntervalSince1970 / 10800) * 10800
        var allData: [AmedasData] = []

        try await withThrowingTaskGroup(of: [AmedasData].self) { group in
            for i in 0...8 {
                let tm = tm0 - Double(10800 * i)
                    
                group.addTask {
                    return try await loadPointFile(point: point, date: Date(timeIntervalSince1970: tm))
                }
            }
            // 子タスクから結果を完了した順に allData に追加
            for try await list in group {
                allData.append(contentsOf: list)
            }
        }
        // 全ての読み込みが完了したら、時系列にsortして返す
        return allData.sorted(by: {$0.time < $1.time})
    }
    
    // 指定地点の時系列観測値(1ファイル、最大3時間分)を取得
//    private func loadPointFile(point: String, date: Date, completion: @escaping (Result<[AmedasData], LoadError>) -> Void) {
//        dateFormatter.dateFormat = "yyyyMMdd_HH"
//        let urlString = String(format: API.amedasPointData, point, dateFormatter.string(from: date))
//        guard let url = URL(string: urlString) else {
//            completion(.failure(.wrongUrl))
//            return
//        }
//
//        LOG("load: " + urlString)
//        let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
//            guard let data = data, error == nil else {
//                LOG("http error.")
//                completion(.failure(.httpError))
//                return
//            }
//
//            guard let list = parseAmedasPointData(data: data, point: point) else {
//                LOG("json parse error.")
//                completion(.failure(.parseError))
//                return
//            }
//
//            completion(.success(list))
//        }
//        task.resume()
//    }

    private func loadPointFile(point: String, date: Date) async throws -> [AmedasData] {
        dateFormatter.dateFormat = "yyyyMMdd_HH"
        let urlString = String(format: API.amedasPointData, point, dateFormatter.string(from: date))
        guard let url = URL(string: urlString) else {
            throw LoadError.wrongUrl
        }
        LOG("load: " + urlString)
        let (data, _) = try await URLSession.shared.data2(for: URLRequest(url: url))
        guard let list = parseAmedasPointData(data: data, point: point) else {
            throw LoadError.parseError
        }
        return list
    }

    private func parseAmedasPointData(data: Data, point: String) -> [AmedasData]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            return nil
        }

        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        var list: [AmedasData] = []
        for item in json {
            guard let date = dateFormatter.date(from: item.key) else { continue }
            let obs = AmedasData(pointID:          point,
                                 time:             date.timeIntervalSince1970,
                                 temperature:      parseDouble(item.value["temp"]),
                                 precipitation1h:  parseDouble(item.value["precipitation1h"]),
                                 precipitation10m: parseDouble(item.value["precipitation10m"]),
                                 windDirection:    parseInt(item.value["windDirection"]),
                                 windSpeed:        parseDouble(item.value["wind"]),
                                 sun1h:            parseDouble(item.value["sun1h"]),
                                 humidity:         parseDouble(item.value["humidity"]))
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
