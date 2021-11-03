//
//  AmedasPoint.swift
//  AmedasMap
//
//  Created by tasshy on 2021/02/28.
//

import Foundation

// MARK: - AmedasPoint
struct AmedasPoint: CustomStringConvertible {
    let pointID: String
    let pointNameJa: String
    let pointNameEn: String
    let latitude: Double
    let longitude: Double
    
    var description: String {
        String(format: "%@(%@) %.2f, %.2f", pointNameJa, pointID, latitude, longitude)
    }
}

// MARK: - AmedasTableLoader
struct AmedasTableLoader {
    enum LoadError: Error {
        case wrongUrl
        case httpError
        case parseError
    }
    
//    func load(completion: @escaping (Result<[String: AmedasPoint], LoadError>) -> Void) {
//        guard let url = URL(string: API.amedasPointTable) else {
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
//            guard let list = parseAmedasTable(data: data) else {
//                LOG("json parse error.")
//                completion(.failure(.parseError))
//                return
//            }
//
//            completion(.success(list))
//        }
//        task.resume()
//    }
    
    func load() async throws -> [String: AmedasPoint] {
        guard let url = URL(string: API.amedasPointTable) else {
            throw LoadError.wrongUrl
        }
        LOG("load: " + url.absoluteString)
        let (data, _) = try await URLSession.shared.data2(for: URLRequest(url: url))
        
        guard let list = parseAmedasTable(data: data) else {
            LOG("json parse error.")
            throw LoadError.parseError
        }
        return list
    }

    func parseAmedasTable(data: Data) -> [String: AmedasPoint]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            return nil
        }

        var list: [String: AmedasPoint] = [:]
        for item in json {
            let pointID = item.key
            guard let pointNameJa = item.value["kjName"] as? String,
                let pointNameEn = item.value["enName"] as? String,
                let lats = item.value["lat"] as? [Double], lats.count == 2,
                let lons = item.value["lon"] as? [Double], lons.count == 2 else {
                continue
            }

            let point = AmedasPoint(pointID: pointID,
                                    pointNameJa: pointNameJa,
                                    pointNameEn: pointNameEn,
                                    latitude: lats[0] + lats[1] / 60,
                                    longitude: lons[0] + lons[1] / 60)
            list[pointID] = point
        }
        return list
    }
}
