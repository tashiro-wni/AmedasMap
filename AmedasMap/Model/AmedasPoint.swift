//
//  AmedasPoint.swift
//  AmedasMap
//
//  Created by tasshy on 2021/02/28.
//

import Foundation

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

struct AmedasTableLoader {
    enum LoadError: Error {
        case wrongUrl
        case httpError
        case parseError
    }
    
    func load(completion: @escaping (Result<[AmedasPoint], LoadError>) -> Void) {
        let urlString = "https://www.jma.go.jp/bosai/amedas/const/amedastable.json"
        guard let url = URL(string: urlString) else {
            completion(.failure(.wrongUrl))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard let data = data, error == nil else {
                LOG("http error.")
                completion(.failure(.httpError))
                return
            }
            
            guard let list = parseAmedasTable(data: data) else {
                LOG("json parse error.")
                completion(.failure(.parseError))
                return
            }
            
//            for point in list {
//                LOG(point.description)
//            }
            completion(.success(list))
        }
        task.resume()
    }
    
    func parseAmedasTable(data: Data) -> [AmedasPoint]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            return nil
        }

        var list: [AmedasPoint] = []
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
            list.append(point)
        }
        list.sort { $0.pointID < $1.pointID }
        return list
    }
}
