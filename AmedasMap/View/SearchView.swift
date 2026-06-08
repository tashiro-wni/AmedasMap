//
//  SearchView.swift
//  AmedasMap
//
//  Created by tasshy on 2023/06/18.
//  地点検索

import SwiftUI

struct SearchView: View {
    @Environment(AmedasMapViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
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
