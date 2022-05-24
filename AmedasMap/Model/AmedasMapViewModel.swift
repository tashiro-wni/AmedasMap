//
//  AmedasMapViewModel.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/01.
//

import Foundation

// MARK: - AmedasMapViewModel
final class AmedasMapViewModel: ObservableObject {
    @Published private(set) var amedasPoints: [String: AmedasPoint] = [:]
    @Published private(set) var amedasData: [AmedasData] = []
    @Published private(set) var date: Date?
    var dateText: String {
        if let date = date {
            return dateFormatter.string(from: date)
        } else {
            return "Loading..."
        }
    }
    @Published var hasError = false
    var errorMessage: String {
        hasError ? "データが読み込めませんでした。" : ""
    }
    @Published var displayElement: AmedasElement = .temperature
    
    @Published var showModal: Bool = false
    private(set) var selectedPoint: String = ""
    private(set) var selectedPointData: [AmedasData] = [] {
        didSet {
            showModal = true
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/M/d H:mm"
        dateFormatter.locale = .posix
        dateFormatter.timeZone = .jst
        return dateFormatter
    }()
    //private let loader = ()
    
    // MARK: -
    init() {
        Task() {
            await loadPoints()
            await loadMapData()
        }
    }
    
    func reload() {
        Task() {
            await loadMapData()
        }
    }
    
    // 地点リストを読み込み
    @MainActor
    private func loadPoints() async {
        LOG(#function)
        do {
            let points = try await AmedasTableLoader.load()
            hasError = false
            amedasPoints = points
            LOG("update amedasPoints \(points.count) points.")
        } catch {
            hasError = true
        }
    }

    // 最新の観測データを読み込み
    @MainActor
    private func loadMapData() async {
        LOG(#function)
        do {
            let result = try await AmedasDataLoader.load()
            hasError = false
            amedasData = result.data
            date = result.date
            LOG("update amedasData \(dateText), \(result.data.count) points.")
        } catch {
            hasError = true
        }
    }

    // 指定地点の時系列データを読み込み
    @MainActor
    func loadPointData(_ point: String) {
        LOG(#function + ", point:\(point)")
        guard let date = date else { return }
        selectedPoint = point

        Task() {
            do {
                selectedPointData = try await AmedasDataLoader.load(point: point, date: date)
                hasError = false
            } catch {
                hasError = true
            }
        }
    }
}
