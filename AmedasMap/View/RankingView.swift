//
//  RankingView.swift
//  AmedasMap
//
//  Created by tasshy on 2023/07/17.
//

import SwiftUI

struct RankingView: View {
    @EnvironmentObject private var viewModel: AmedasMapViewModel
    
    var body: some View {
        ScrollView(.vertical) {
            Grid(alignment: .trailing) {
                ForEach(viewModel.makeRanking(element: viewModel.displayElement).prefix(30), id: \.self) { data in
                    let pointName = viewModel.amedasPoints[data.pointID]?.pointNameJa ?? ""
                    let value = data.text(for: viewModel.displayElement)
                    
                    GridRow() {
                        Text(pointName)
                        Text(value)
                        Spacer()
                    }
                    Divider()
                }
            }            
        }
    }
}
