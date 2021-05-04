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
//            for item in selectedPointData {
//                self.dateFormatter.dateFormat = "M/dd H:mm"
//                LOG("point: \(item.pointID), "
//                        + self.dateFormatter.string(from: Date(timeIntervalSince1970: item.time))
//                        + "temp: " + item.text(for: .temperature))
//            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/M/d HH:mm"
        dateFormatter.locale = LocalePOSIX
        dateFormatter.timeZone = TimeZoneJST
        return dateFormatter
    }()
    private let loader = AmedasDataLoader()
    
    // MARK: -
    init() {
        loadPoints()
        loadMapData()
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
    func loadMapData() {
        LOG(#function)
        hasError = false

        loader.load() { [weak self] result in
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
    
    // 指定地点の時系列データを読み込み
    func loadPointData(_ point: String) {
        LOG(#function + ", point:\(point)")
        guard let date = date else { return }
        selectedPoint = point
        loader.load(point: point, date: date) { result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    self.selectedPointData = data                
                case .failure:
                    self.hasError = true
                }
            }
        }
    }
}
