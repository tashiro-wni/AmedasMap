//
//  API.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/01.
//

import Foundation

enum API {
    private static let baseUrl = "https://www.jma.go.jp/bosai/amedas"
    static let amedasPointTable = baseUrl + "/const/amedastable.json"  // アメダス 地点リスト
    static let amedasLatestTime = baseUrl + "/data/latest_time.txt"    // アメダス 最新データの時刻
    static let amedasMapData    = baseUrl + "/data/map/%@00.json"      // アメダス 指定時刻の観測値
    static let amedasPointData  = baseUrl + "/data/point/%@/%@.json"   // アメダス 指定地点の時系列観測値
}
