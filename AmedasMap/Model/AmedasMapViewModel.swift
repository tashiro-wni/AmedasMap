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
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/M/d HH:mm"
        dateFormatter.locale = LocalePOSIX
        dateFormatter.timeZone = TimeZoneJST
        return dateFormatter
    }()
    
    // MARK: -
    init() {
        loadPoints()
        loadData()
    }
    
    // 地点リストを読み込み
    private func loadPoints() {
        hasError = false

        AmedasTableLoader().load() { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success(let points):
                    LOG("update amedasPoints \(points.count) points.")
                    self?.amedasPoints = points
                    
                case .failure:
                    self?.hasError = true
                }
            }
        }
    }
    
    // 最新の観測データを読み込み
    func loadData() {
        LOG(#function)
        hasError = false

        AmedasDataLoader().load() { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    self.amedasData = data.data
                    self.date = data.date
                    LOG("update amedasData \(self.dateText), \(data.data.count) points.")

                case .failure:
                    self.hasError = true
                }
            }
        }
    }
}
