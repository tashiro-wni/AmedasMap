//
//  SearchView.swift
//  AmedasMap
//
//  Created by tasshy on 2023/06/18.
//  地点検索

import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var viewModel: AmedasMapViewModel
    
    var body: some View {
        VStack {
            TextField("地点を検索", text: $viewModel.searchText)
                .padding(20)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                        
            List {
                ForEach(viewModel.filterdPoints, id: \.pointID) { point in
                    Button(action: { viewModel.loadPointData(point.pointID) }) {
                        Text(point.pointNameJa)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}
