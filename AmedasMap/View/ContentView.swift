//
//  ContentView.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/02.
//

import SwiftUI

extension AmedasElement {
    var image: Image {
        switch self {
        case .temperature:    Image(systemName: "thermometer")
        case .precipitation:  Image(systemName: "cloud.rain")
        case .wind:           Image(systemName: "wind")
        case .sun:            Image(systemName: "sun.max")
        case .humidity:       Image(systemName: "humidity")
        case .pressure:       Image(systemName: "rectangle.compress.vertical")
        case .snow:           Image(systemName: "snowflake")
        }
    }
    
    var rankingAvailable: Bool {
        switch self {
        case .temperature, .precipitation, .wind, .snow:
            true
        default:
            false
        }
    }
}

// MARK: - ElementPicker 表示要素を選択
private struct ElementPicker: View {
    @Environment(AmedasMapViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        Picker(selection: $viewModel.displayElement, label: EmptyView()) {
            ForEach(AmedasElement.allCases, id: \.self) { element in
                element.image.accessibilityLabel(element.title)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(width: 250)
    }
}

// MARK: - TimestampView データの時刻, 再読み込みボタン
private struct TimestampView: View {
    @Environment(AmedasMapViewModel.self) private var viewModel

    var body: some View {
        HStack(spacing: 10) {
            // データの時刻
            Text(viewModel.dateText)
            
            // 再読み込みボタン
            Button(action: { viewModel.reload() }) {
                Image(systemName: "gobackward")
                    .resizable()
                    .padding(8)
                    .frame(width: 30, height: 30)
                    .background(Color.white)
                    .cornerRadius(4)
                    //.accessibilityLabel("再読み込み")
            }
            
            // 検索ボタン
            Button(action: { viewModel.showSearchView = true }) {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .padding(8)
                    .frame(width: 30, height: 30)
                    .background(Color.white)
                    .cornerRadius(4)
                    //.accessibilityLabel("検索")
            }
            
            // ランキング
            Button(action: { viewModel.showRankingView = true }) {
                Image(systemName: "trophy")
                    .resizable()
                    .padding(8)
                    .frame(width: 30, height: 30)
                    .background(Color.white)
                    .cornerRadius(4)
                    //.accessibilityLabel("ランキング")
            }.disabled(!viewModel.displayElement.rankingAvailable)
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @Environment(\.scenePhase) private var phase
    @Environment(AmedasMapViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        ZStack {
            MapView2()

            GeometryReader { geometry in
                if geometry.size.width < 500 {
                    VStack {
                        // 時刻・再読み込みボタン
                        TimestampView()
                        
                        // 表示要素を選択
                        ElementPicker()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(24)
                } else {
                    HStack {
                        // 時刻・再読み込みボタン
                        TimestampView()
                        
                        // 表示要素を選択
                        ElementPicker()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(8)
                }
            }
            
            if viewModel.isLoading {
                LoadingIndicator()
            }
        }
        .sheet(isPresented: $viewModel.showPointView) {
            // 地点詳細
            NavigationView {
                PointView(selectedElement: viewModel.displayElement)
                    .navigationTitle(viewModel.selectedPointName)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(trailing: Button(action: { viewModel.showPointView = false }) {
                        Image(systemName: "xmark")
                    })
            }
        }
        .sheet(isPresented: $viewModel.showSearchView) {
            // 地点検索
            SearchView()
                .presentationDetents([ .medium ])
        }
        .sheet(isPresented: $viewModel.showRankingView) {
            // 地点検索
            NavigationView {
                RankingView()
                    .navigationTitle(viewModel.displayElement.title + "ランキング (" + viewModel.dateText + ")")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(trailing: Button(action: { viewModel.showRankingView = false }) {
                        Image(systemName: "xmark")
                    })
            }
        }
        .alert(isPresented: $viewModel.hasError) {
            // エラー時にはAlertを表示する
            Alert(title: Text(viewModel.errorMessage))
        }
        .onChange(of: phase) {
            if phase == .active {
                LOG("scenePhase changed ACTIVE!!")
                viewModel.reload()
            }
        }
    }
}
