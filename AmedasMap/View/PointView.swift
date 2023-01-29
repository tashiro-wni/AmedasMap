//
//  PointView.swift
//  AmedasMap
//
//  Created by tasshy on 2021/05/04.
//

import SwiftUI

struct PointView: View {
    @EnvironmentObject private var viewModel: AmedasMapViewModel
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
