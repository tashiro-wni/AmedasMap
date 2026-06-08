//
//  AmedasMapViewModel.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/01.
//

import Foundation
import Observation

// MARK: - AmedasMapViewModel
@MainActor
@Observable
final class AmedasMapViewModel {
    private(set) var amedasPoints: [String: AmedasPoint] = [:]
    private(set) var amedasData: [AmedasData] = []
    private(set) var date: Date?
    var dateText: String {
        if let date {
            return dateFormatter.string(from: date)
            //return date.formatted(.dateTime.year().month().day().hour().minute().locale(.ja_JP))
        } else {
            return "Loading..."
        }
    }
    var hasError = false
    var errorMessage: String {
        hasError ? "データが読み込めませんでした。" : ""
    }
    var displayElement: AmedasElement = .temperature

    // 地点詳細画面
    var showPointView: Bool = false
    private(set) var selectedPoint: String = "" {
        didSet {
            selectedPointName = String(format: "%@(%@)",
                                               amedasPoints[selectedPoint]?.pointNameJa ?? "",
                                               selectedPoint)
        }
    }
    private(set) var selectedPointName: String = ""
    private(set) var selectedPointData: [AmedasData] = [] {
        didSet {
            showPointView = true
        }
    }
    private(set) var selectedPointElements: [AmedasElement] = []
    
    // 地点検索
    var showSearchView = false
    var searchText = ""
    var filterdPoints: [AmedasPoint] {
        amedasPoints.values
            .filter { $0.pointNameJa.contains(searchText) }
            .sorted(by: { $0.pointID < $1.pointID })
    }
    
    // ランキング
    var showRankingView = false

    // Data Loading
    var isLoading: Bool { isPointTableLoading || isMapDataLoading || isPointDataLoading }
    private var isPointTableLoading = false
    private var isMapDataLoading = false
    private(set) var isPointDataLoading = false

    @ObservationIgnored
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/M/d H:mm"
        dateFormatter.locale = .posix
        dateFormatter.timeZone = .jst
        return dateFormatter
    }()
    
    // MARK: -
    init() {
        Task {
            await loadPoints()
            await loadMapData()
        }
    }
    
    func reload() {
        Task {
            await loadMapData()
        }
    }
    
    // 地点リストを読み込み
    private func loadPoints() async {
        LOG(#function)
        do {
            isPointTableLoading = true
            let points = try await AmedasTableLoader.load()
            isPointTableLoading = false
            hasError = false
            amedasPoints = points
            LOG("update amedasPoints \(points.count) points.")
        } catch {
            isPointTableLoading = false
            hasError = true
        }
    }

    // 最新の観測データを読み込み
    private func loadMapData() async {
        LOG(#function)
        do {
            isMapDataLoading = true
            let result = try await AmedasDataLoader.load()
            isMapDataLoading = false

            hasError = false
            amedasData = result.data
            date = result.date
            LOG("update amedasData \(dateText), \(result.data.count) points.")
        } catch {
            isMapDataLoading = false
            hasError = true
        }
    }

    // 指定地点の時系列データを読み込み
    func loadPointData(_ point: String) {
        LOG(#function + ", point:\(point)")
        guard let date else { return }
        selectedPoint = point

        Task {
            do {
                isPointDataLoading = true
                selectedPointData = try await AmedasDataLoader.load(point: point, date: date)
                updateSelectedPointElements()
                isPointDataLoading = false
                hasError = false
            } catch {
                isPointDataLoading = false
                hasError = true
            }
        }
    }
    
    // 選択された地点で有効な要素を選び出す
    private func updateSelectedPointElements() {
        var elements: [AmedasElement] = []
        
        for element in AmedasElement.allCases {
            if !selectedPointData.filter({ $0.text(for: element) != $0.invalidText }).isEmpty {
                elements.append(element)
            }
        }
        selectedPointElements = elements
    }
    
    // 要素ごとのランキング
    func makeRanking(element: AmedasElement) -> [AmedasData] {
        switch element {
        case .temperature:
            amedasData
                .filter({ $0.hasValidData(for: element) })
                .sorted(by: { $0.temperature! > $1.temperature! })
        case .precipitation:
            amedasData
                .filter({ $0.hasValidData(for: element) })
                .sorted(by: { $0.precipitation1h! > $1.precipitation1h! })
        case .wind:
            amedasData
                .filter({ $0.hasValidData(for: element) })
                .sorted(by: { $0.windSpeed! > $1.windSpeed! })
        case .snow:
            amedasData
                .filter({ $0.hasValidData(for: element) })
                .sorted(by: { $0.snow! > $1.snow! })
        default:
            []
        }
    }
}
