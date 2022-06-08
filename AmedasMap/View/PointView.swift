//
//  PointView.swift
//  AmedasMap
//
//  Created by tasshy on 2021/05/04.
//

import SwiftUI

struct PointView: View {
    @StateObject var viewModel: AmedasMapViewModel

    private var pointName: String {
        String(format: "%@(%@)",
               viewModel.amedasPoints[viewModel.selectedPoint]?.pointNameJa ?? "",
               viewModel.selectedPoint) }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Text(pointName)
                    .font(.title)
                    .padding(12)
                // 選択地点のデータを時刻の新しい順に取り出し、正時(00分)のデータを24個取り出す
                List(viewModel.selectedPointData.reversed().filter{ $0.is0min }.prefix(24), id: \.self) { item in
                    //Text(formattedText(item, width: geometry.size.width))
                    //    .lineLimit(1)
                    Colmun(item: item, width: geometry.size.width)
                }
                .listStyle(.plain)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
    }
}
    
struct Colmun: View {
    let item: AmedasData
    let width: CGFloat
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H:mm"
        dateFormatter.locale = .posix
        dateFormatter.timeZone = .jst
        return dateFormatter
    }()
    
    var body: some View {
        HStack {
            Text(dateFormatter.string(from: Date(timeIntervalSince1970: item.time)))
                .frame(width: 50, alignment: .trailing)
            
            if item.hasValidData(for: .temperature) {
                Text(item.text(for: .temperature))
                    .frame(width: 70, alignment: .trailing)
            }
            if item.text(for: .precipitation) != item.invalidText {
                Text(item.text(for: .precipitation))
                    .frame(width: 90, alignment: .trailing)
            }
            if item.hasValidData(for: .wind) {
                Text(item.text(for: .wind))
                    .frame(width: 120, alignment: .trailing)
            }
            if width > 500, item.hasValidData(for: .sun) {
                Text(item.text(for: .sun))
                    .frame(width: 60, alignment: .trailing)
            }
            if width > 500, item.hasValidData(for: .humidity) {
                Text(item.text(for: .humidity))
                    .frame(width: 50, alignment: .trailing)
            }
            if width > 500, item.hasValidData(for: .pressure) {
                Text(item.text(for: .pressure))
                    .frame(width: 90, alignment: .trailing)
            }
        }
    }
}
    
//    private func formattedText(_ item: AmedasData, width: CGFloat) -> String {
//        var texts: [String] = []
//        texts.append(dateFormatter.string(from: Date(timeIntervalSince1970: item.time)))
//        if item.hasValidData(for: .temperature) {
//            texts.append("🌡" + item.text(for: .temperature))
//        }
//        if item.text(for: .precipitation) != item.invalidText {
//            texts.append("☂️" + item.text(for: .precipitation))
//        }
//        if item.hasValidData(for: .wind) {
//            texts.append("🎐" + item.text(for: .wind))
//        }
//        if width > 500, item.hasValidData(for: .sun) {
//            texts.append("☀️" + item.text(for: .sun))
//        }
//        if width > 500, item.hasValidData(for: .humidity) {
//            texts.append("💦" + item.text(for: .humidity))
//        }
//        return texts.joined(separator: ", ")
//    }

