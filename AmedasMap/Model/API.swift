//
//  API.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/01.
//

enum API {
    static let amedasPointTable = "https://www.jma.go.jp/bosai/amedas/const/amedastable.json"  // アメダス 地点リスト
    static let amedasLatestTime = "https://www.jma.go.jp/bosai/amedas/data/latest_time.txt"    // アメダス 最新データの時刻
    static let amedasMapData    = "https://www.jma.go.jp/bosai/amedas/data/map/%@00.json"      // アメダス 指定時刻の観測値
}
