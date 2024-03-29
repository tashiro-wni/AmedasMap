//
//  AmedasData.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/01.
//

import Foundation

enum AmedasElement: CaseIterable {
    case temperature, precipitation, wind, sun, humidity, pressure, snow

    var title: String {
        switch self {
        case .temperature:    return "気温"
        case .precipitation:  return "降水量"
        case .wind:           return "風速"
        case .sun:            return "日照"
        case .humidity:       return "湿度"
        case .pressure:       return "気圧"
        case .snow:           return "積雪深"
        }
    }
}

// MARK: - AmedasData
struct AmedasData: Hashable, Identifiable, CustomStringConvertible {
    let id = UUID()
    let pointID: String
    let date: Date
    let temperature: Double?
    let precipitation1h: Double?
    let precipitation10m: Double?
    let windDirection: Int?
    let windSpeed: Double?
    let sun1h: Double?
    let humidity: Double?
    let pressure: Double?
    let snow: Double?

    var is0min: Bool {  // 00分
        Int(date.timeIntervalSince1970).isMultiple(of: 3600)
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
            guard let precipitation1h else { return false }
            return precipitation1h > 0
        case .wind:
            guard let windDirection, windDirection >= 0, windDirection < directionText.count else { return false }
            return windSpeed != nil
        case .sun:
            return sun1h != nil
        case .humidity:
            return humidity != nil
        case .pressure:
            return pressure != nil
        case .snow:
            guard let snow else { return false }
            return snow > 0
        }
    }

    func value(for element: AmedasElement) -> Double? {
        switch element {
        case .temperature:
            return temperature
        case .precipitation:
            return precipitation1h
        case .wind:
            return windSpeed
        case .sun:
            return sun1h
        case .humidity:
            return humidity
        case .pressure:
            return pressure
        case .snow:
            return snow
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
        case .pressure:
            return pressureText
        case .snow:
            return snowText
        }
    }
    
    private var temperatureText: String {
        guard let temperature else { return invalidText }
        return String(format: "%.1f℃", temperature)
    }

    private var precipitationText: String {
        guard let precipitation1h else { return invalidText }
        return String(format: "%.1fmm/h", precipitation1h)
    }

    private var windText: String {
        guard let windDirection, windDirection >= 0, windDirection < directionText.count,
              let windSpeed else { return invalidText }
        return String(format: "%@ %.1fm/s", directionText[windDirection], windSpeed)
    }
    
    private var sunText: String {
        guard let sun1h else { return invalidText }
        return String(format: "%.0fmin", sun1h * 60)
    }
    
    private var humidityText: String {
        guard let humidity else { return invalidText }
        return String(format: "%.0f%%", humidity)
    }
    
    private var pressureText: String {
        guard let pressure else { return invalidText }
        return String(format: "%.1fhPa", pressure)
    }
    
    private var snowText: String {
        guard let snow else { return invalidText }
        return String(format: "%.0fcm", snow)
    }

    var description: String {
        var ary: [String] = []
        ary.append(pointID)
        ary.append("time:\(date.timeIntervalSince1970)")
        ary.append("temp:" + temperatureText)
        ary.append("prec:" + precipitationText)
        ary.append("wind:" + windText)
        ary.append("sun:" + sunText)
        ary.append("hum:" + humidityText)
        ary.append("pres:" + pressureText)
        ary.append("snow:" + snowText)

        return ary.joined(separator: ", ")
    }
}

// MARK: - AmedasDataLoader
enum AmedasDataLoader {
    struct AmedasMapReult {
        let date: Date
        let data: [AmedasData]
    }
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .posix
        dateFormatter.timeZone = .jst
        return dateFormatter
    }()
    
    // 最新データの時刻を取得
    static func load() async throws -> AmedasMapReult {
        guard let url = URL(string: API.amedasLatestTime) else {
            throw LoadError.wrongUrl
        }
        LOG("load: " + url.absoluteString)
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .jst
        
        guard let text = String(data: data, encoding: .utf8),
              let date = formatter.date(from: text) else {
                  throw LoadError.parseError
              }
        return try await load(date: date)
    }
    
    // 指定時刻の観測値一覧を取得
    private static func load(date: Date) async throws -> AmedasMapReult {
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        let urlString = String(format: API.amedasMapData, dateFormatter.string(from: date))
        guard let url = URL(string: urlString) else {
            throw LoadError.wrongUrl
        }
        LOG("load: " + urlString)
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let list = parseAmedasMapData(data: data, date: date) else {
            throw LoadError.parseError
        }
        return AmedasMapReult(date: date, data: list)
    }

    static func parseAmedasMapData(data: Data, date: Date) -> [AmedasData]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            return nil
        }

        var list: [AmedasData] = []
        for item in json {
            let obs = AmedasData(pointID:          item.key,
                                 date:             date,
                                 temperature:      parseDouble(item.value["temp"]),
                                 precipitation1h:  parseDouble(item.value["precipitation1h"]),
                                 precipitation10m: parseDouble(item.value["precipitation10m"]),
                                 windDirection:    parseInt(item.value["windDirection"]),
                                 windSpeed:        parseDouble(item.value["wind"]),
                                 sun1h:            parseDouble(item.value["sun1h"]),
                                 humidity:         parseDouble(item.value["humidity"]),
                                 pressure:         parseDouble(item.value["pressure"]),
                                 snow:             parseDouble(item.value["snow"]))
            list.append(obs)
        }
        return list
    }

    // 指定地点の時系列観測値(過去24時間分)を取得
    static func load(point: String, date: Date) async throws -> [AmedasData] {
        let tm0 = floor(date.timeIntervalSince1970 / 10800) * 10800
        var allData: [AmedasData] = []

        try await withThrowingTaskGroup(of: [AmedasData].self) { group in
            // API 1回で3時間分のデータを取得できるので、9回呼んで24時間分+αのデータを取得
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
        // 全ての読み込みが完了したら、時系列にsortして直近24時間分を返す
        return allData.sorted(by: {$0.date < $1.date}).suffix(24 * 6)
    }
    
    // 指定地点の時系列観測値(1ファイル、最大3時間分)を取得
    private static func loadPointFile(point: String, date: Date) async throws -> [AmedasData] {
        dateFormatter.dateFormat = "yyyyMMdd_HH"
        let urlString = String(format: API.amedasPointData, point, dateFormatter.string(from: date))
        guard let url = URL(string: urlString) else {
            throw LoadError.wrongUrl
        }
        LOG("load: " + urlString)
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let list = parseAmedasPointData(data: data, point: point) else {
            throw LoadError.parseError
        }
        return list
    }

    private static func parseAmedasPointData(data: Data, point: String) -> [AmedasData]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            return nil
        }

        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        var list: [AmedasData] = []
        for item in json {
            guard let date = dateFormatter.date(from: item.key) else { continue }
            let obs = AmedasData(pointID:          point,
                                 date:             date,
                                 temperature:      parseDouble(item.value["temp"]),
                                 precipitation1h:  parseDouble(item.value["precipitation1h"]),
                                 precipitation10m: parseDouble(item.value["precipitation10m"]),
                                 windDirection:    parseInt(item.value["windDirection"]),
                                 windSpeed:        parseDouble(item.value["wind"]),
                                 sun1h:            parseDouble(item.value["sun1h"]),
                                 humidity:         parseDouble(item.value["humidity"]),
                                 pressure:         parseDouble(item.value["pressure"]),
                                 snow:             parseDouble(item.value["snow"])
            )
            list.append(obs)
        }
        return list
    }
    
    private static func parseDouble(_ value: Any?) -> Double? {
        guard let val = value as? [Double], val.count == 2 else { return nil }
        if val[1] == 0 {
            return val[0]
        } else {
            return nil
        }
    }
    
    private static func parseInt(_ value: Any?) -> Int? {
        guard let val = value as? [Int], val.count == 2 else { return nil }
        if val[1] == 0 {
            return val[0]
        } else {
            return nil
        }
    }
}
