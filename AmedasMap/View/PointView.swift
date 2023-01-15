//
//  PointView.swift
//  AmedasMap
//
//  Created by tasshy on 2021/05/04.
//

import SwiftUI
import Charts

private extension AmedasElement {
    enum ChartType {
        case line, bar, area
    }
    
    var chartType: ChartType {
        switch self {
        case .temperature:    return .line
        case .precipitation:  return .bar
        case .wind:           return .line
        case .sun:            return .bar
        case .humidity:       return .line
        case .pressure:       return .line
        case .snow:           return .area
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
        case .snow:           return .cyan
        }
    }

    var chartRange: (min: Double?, max: Double?) {
        switch self {
        case .temperature:    return (min: nil, max: nil)
        case .precipitation:  return (min: 0.0, max: 4.0)
        case .wind:           return (min: 0.0, max: nil)
        case .sun:            return (min: 0.0, max: 1.0)
        case .humidity:       return (min: 0.0, max: 100.0)
        case .pressure:       return (min: nil, max: nil)
        case .snow:           return (min: 0.0, max: 4.0)
        }
    }
}

// MARK: -
struct PointView: View {
    @StateObject var viewModel: AmedasMapViewModel
    @State var selectedElement: AmedasElement

    // 画面が縦向きなら最大3要素、横向きなら最大7要素表示する
    private func displayElements(_ geometry: GeometryProxy) -> [AmedasElement] {
        let max = geometry.size.width > geometry.size.height ? 7 : 3
        return Array(viewModel.selectedPointElements.prefix(max))
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                // グラフ
                Text(selectedElement.title)
                    .bold()
                AmedasChartView(data: viewModel.selectedPointData, element: selectedElement)
                    .frame(width: geometry.size.width - 40)
                
                // グラフ要素を選択
                if viewModel.selectedPointElements.count > 1 {
                    Picker(selection: $selectedElement, label: EmptyView()) {
                        ForEach(viewModel.selectedPointElements, id: \.self) { element in
                            element.image.accessibilityLabel(element.title)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 250)
                }
                Divider()
                
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
                    ForEach(viewModel.selectedPointData.reversed().filter{ $0.is0min }, id: \.self) { item in
                        // 各時刻の観測値
                        GridRow() {
                            Text(item.date, format: .dateTime.hour().minute())
                            
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
        .environment(\.locale, .ja_JP)
    }
}

// MARK: - AmedasChartView グラフ+吹き出し
struct AmedasChartView: View {
    let data: [AmedasData]
    let element: AmedasElement
    @State private var selectedItem: (date: Date, text: String)? = nil
    @Environment(\.layoutDirection) var layoutDirection

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(element.title)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .opacity(selectedItem == nil ? 1 : 0)

            InteractiveAmedasChart(data: data, element: element, selectedItem: $selectedItem)
                .frame(height: 150)
        }
        .chartBackground { proxy in
            ZStack(alignment: .topTrailing) {
                GeometryReader { nthGeoItem in
                    if let selectedItem = selectedItem {
                        let dateInterval = Calendar.current.dateInterval(of: .minute, for: selectedItem.date)!
                        let startPositionX1 = proxy.position(forX: dateInterval.start) ?? 0
                        let startPositionX2 = proxy.position(forX: dateInterval.end) ?? 0
                        let midStartPositionX = (startPositionX1 + startPositionX2) / 2 + nthGeoItem[proxy.plotAreaFrame].origin.x

                        let lineX = layoutDirection == .rightToLeft ? nthGeoItem.size.width - midStartPositionX : midStartPositionX
                        let lineHeight = nthGeoItem[proxy.plotAreaFrame].maxY
                        let boxWidth: CGFloat = 110
                        let boxOffset = max(0, min(nthGeoItem.size.width - boxWidth, lineX - boxWidth / 2))

                        // 吹き出し
                        Rectangle()
                            .fill(.quaternary)
                            .frame(width: 2, height: lineHeight)
                            .position(x: lineX, y: lineHeight / 2)

                        VStack(alignment: .trailing) {
                            Text(selectedItem.date, format: .dateTime.month().day().hour().minute())
                            //Text(selectedItem.date.formatted(date: .short, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(selectedItem.text)
                                .font(.callout.bold())
                                .foregroundColor(.primary)
                        }
                        .frame(width: boxWidth, alignment: .trailing)
                        .background {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.background)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.quaternary.opacity(0.7))
                            }
                            .padding([.leading, .trailing], -8)
                            .padding([.top, .bottom], -4)
                        }
                        .offset(x: boxOffset)
                    }
                }
            }
        }
    }
}

// MARK: - InteractiveAmedasChart グラフ
struct InteractiveAmedasChart: View {
    let data: [AmedasData]
    let element: AmedasElement
    @Binding var selectedItem: (date: Date, text: String)?

    // グラフのY軸描画範囲を決定
    func makeRange() -> (Double?, Double?) {
        guard let min = data.compactMap({ $0.value(for: element) }).min(),
              let max = data.compactMap({ $0.value(for: element) }).max() else {
            return (nil, nil)
        }

        return ( [ floor(min), element.chartRange.min ].compactMap({ $0 }).min(),
                 [ ceil(max), element.chartRange.max ].compactMap({ $0 }).max() )
    }

    // 触れている箇所の座標から値を取得
    func findItem(location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> (date: Date, text: String)? {
        let relativeXPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
        guard let date = proxy.value(atX: relativeXPosition) as Date? else { return nil }

        // Find the closest date element.
        var minDistance: TimeInterval = .infinity
        var index: Int? = nil
        for i in data.indices {
            let distance = data[i].date.distance(to: date)
            if abs(distance) < minDistance, data[i].value(for: element) != nil {
                minDistance = abs(distance)
                index = i
            }
        }
        if let index {
            return (date: data[index].date, text: data[index].text(for: element))
        } else {
            return nil
        }
    }

    var body: some View {
        let (min, max) = makeRange()
        if let min = min, let max = max {
            Chart(data, id: \.self) { item in
                if let value = item.value(for: element) {
                    switch element.chartType {
                    case .line:
                        LineMark(
                            x: .value("時刻", item.date, unit: .minute),
                            y: .value(element.title, value)
                        )
                        .foregroundStyle(element.chartColor)
                    case .bar:
                        BarMark(
                            x: .value("時刻", item.date, unit: .minute),
                            y: .value(element.title, value),
                            width: 2
                        )
                        .foregroundStyle(element.chartColor)
                    case .area:
                        AreaMark(
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
                    if value.as(Date.self)!.showAxisLabel {
                        AxisTick()
                        // see Date.FormatStyle
                        // https://developer.apple.com/documentation/foundation/date/formatstyle
                        // DateFormatter "H" 相当、必要なら .locale() を追加
                        AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { nthGeometryItem in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture()  // グラフに触れている座標から、どの時刻に触れているのか検出
                                .onEnded { value in
                                    let item = findItem(location: value.location, proxy: proxy, geometry: nthGeometryItem)
                                    if selectedItem?.date == item?.date {
                                        // If tapping the same element, clear the selection.
                                        selectedItem = nil
                                    } else {
                                        selectedItem = item
                                    }
                                }
                                .exclusively(
                                    before: DragGesture()
                                        .onChanged { value in
                                            selectedItem = findItem(location: value.location, proxy: proxy, geometry: nthGeometryItem)
                                        }
                                )
                        )
                }
            }
        } else {
            EmptyView()
        }
    }
}

private extension Date {
    // グラフのX軸にラベルを表示するか？
    var showAxisLabel: Bool {
        Int(timeIntervalSince1970).isMultiple(of: 3600 * 3)
    }
}
