//
//  PointView.swift
//  AmedasMap
//
//  Created by tasshy on 2021/05/04.
//

import SwiftUI

private extension AmedasElement {
    var title: String {
        switch self {
        case .temperature:    return "気温"
        case .precipitation:  return "降水量"
        case .wind:           return "風向風速"
        case .sun:            return "日照"
        case .humidity:       return "湿度"
        case .pressure:       return "気圧"
        }
    }
}

struct PointView: View {
    @StateObject var viewModel: AmedasMapViewModel

    private var pointName: String {
        String(format: "%@(%@)",
               viewModel.amedasPoints[viewModel.selectedPoint]?.pointNameJa ?? "",
               viewModel.selectedPoint) }

    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H:mm"
        dateFormatter.locale = .posix
        dateFormatter.timeZone = .jst
        return dateFormatter
    }()

    // 画面が縦向きなら最大3要素、横向きなら最大6要素表示する
    private func displayElements(_ geometry: GeometryProxy) -> [AmedasElement] {
        let max = geometry.size.width > geometry.size.height ? 6 : 3
        return Array(viewModel.selectedPointElements.prefix(max))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Text(pointName)
                    .font(.title)
                    .padding(12)

                ScrollView(.vertical) {
                    // 表で表示する
                    Grid(alignment: .trailing) {
                        // 要素名
                        GridRow() {
                            Text("時刻")
                            
                            ForEach(displayElements(geometry), id: \.self) { element in
                                Text(element.title)
                            }
                            Spacer()
                        }
                        .lineLimit(1)
                        Divider()
                        
                        // 選択地点のデータを時刻の新しい順に取り出し、正時(00分)のデータを24個取り出す
                        ForEach(viewModel.selectedPointData.reversed().filter{ $0.is0min }.prefix(24), id: \.self) { item in
                            // 各時刻の観測値
                            GridRow() {
                                Text(dateFormatter.string(from: Date(timeIntervalSince1970: item.time)))
                                
                                ForEach(displayElements(geometry), id: \.self) { element in
                                    Text(item.text(for: element))
                                }
                                Spacer()
                            }
                            .lineLimit(1)
                            Divider()
                        }
                    }
                }
            }
        }
    }
}
