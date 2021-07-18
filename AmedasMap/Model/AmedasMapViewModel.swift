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
        dateFormatter.locale = LocalePOSIX
        dateFormatter.timeZone = TimeZoneJST
        return dateFormatter
    }()
    private let loader = AmedasDataLoader()
    
    // MARK: -
    init() {
        if #available(iOS 15.0, *) {
            Task() {
                await self.loadPoints2()
                await self.loadMapData2()
            }
        } else {
            loadPoints()
            loadMapData()
        }
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
    
    @available(iOS 15.0, *)
    func loadPoints2() async {
        LOG(#function)
        //hasError = false
        do {
            let points = try await AmedasTableLoader().load()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.hasError = false
                self.amedasPoints = points
                LOG("update amedasPoints \(points.count) points.")
            }
        } catch {
            hasError = true
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
    
    @available(iOS 15.0, *)
    func loadMapData2() async {
        LOG(#function)
        do {
            let data = try await loader.load()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.hasError = false
                self.amedasData = data.data
                self.date = data.date
                LOG("update amedasData \(self.dateText), \(data.data.count) points.")
            }
        } catch {
            hasError = true
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
