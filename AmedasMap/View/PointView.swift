//
//  PointView.swift
//  AmedasMap
//
//  Created by tasshy on 2021/05/04.
//

import SwiftUI
import Charts

private extension AmedasElement {
    var title: String {
        switch self {
        case .temperature:    return "気温"
        case .precipitation:  return "降水量"
        case .wind:           return "風速"
        case .sun:            return "日照"
        case .humidity:       return "湿度"
        case .pressure:       return "気圧"
        }
    }
    
    enum ChartType {
        case line, bar
    }
    
    var chartType: ChartType {
        switch self {
        case .temperature:    return .line
        case .precipitation:  return .bar
        case .wind:           return .line
        case .sun:            return .bar
        case .humidity:       return .line
        case .pressure:       return .line
        }
    }
    
    var chartColor: Color {
        switch self {
        case .temperature:    return .red
        case .precipitation:  return .blue
        case .wind:           return .green
        case .sun:            return .orange
        case .humidity:       return .cyan
        case .pressure:       return .green
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
                    // 気温グラフ
                    ForEach(viewModel.selectedPointElements, id: \.self) { element in
                        if viewModel.selectedPointElements.contains(element) {
                            Text(element.title)
                                .bold()
                            AmedasChartView(data: viewModel.selectedPointData.suffix(24 * 6), element: element)
                                .frame(width: geometry.size.width - 40, height: 150)
                            Divider()
                        }
                    }

                    // 表
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
                        .bold()
                        Divider()
                        
                        // 選択地点のデータを時刻の新しい順に取り出し、正時(00分)のデータを24個取り出す
                        ForEach(viewModel.selectedPointData.reversed().filter{ $0.is0min }.prefix(24), id: \.self) { item in
                            // 各時刻の観測値
                            GridRow() {
                                Text(dateFormatter.string(from: item.date))
                                
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

// MARK: - AmedasChartView 要素ごとのグラフ
struct AmedasChartView: View {
    let data: [AmedasData]
    let element: AmedasElement
    
    var body: some View {
        if let min = data.compactMap({ $0.value(for: element) }).min(),
           let max = data.compactMap({ $0.value(for: element) }).max() {
            Chart(data, id: \.self) { item in
                if let value = item.value(for: element) {
                    if element.chartType == .bar {
                        BarMark(
                            x: .value("時刻", item.date, unit: .minute),
                            y: .value(element.title, value),
                            width: 2
                        )
                        .foregroundStyle(element.chartColor)
                    } else {
                        LineMark(
                            x: .value("時刻", item.date, unit: .minute),
                            y: .value(element.title, value)
                        )
                        .foregroundStyle(element.chartColor)
                    }
                }
            }
            .chartYScale(domain: min ... max)  // Y軸の描画範囲を指定
            .chartXAxis {  // X軸の表記を定義
                AxisMarks(values: .stride(by: .hour)) { value in
                    AxisGridLine()
                    // 3時間ごとにX軸に時刻を表示
                    if Int(value.as(Date.self)!.timeIntervalSince1970).isMultiple(of: 3600 * 3) {
                        AxisTick()
                        // see Date.FormatStyle
                        // https://developer.apple.com/documentation/foundation/date/formatstyle
                        // DateFormatter "H" 相当、必要なら .locale() を追加
                        AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
}
