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
        case .temperature:    return Image(systemName: "thermometer")
        case .precipitation:  return Image(systemName: "cloud.rain")
        case .wind:           return Image(systemName: "wind")
        case .sun:            return Image(systemName: "sun.max")
        case .humidity:       return Image(systemName: "humidity")
        case .pressure:       return Image(systemName: "rectangle.compress.vertical")
        case .snow:           return Image(systemName: "snowflake")
        }
    }
}

// MARK: - ElementPicker 表示要素を選択
private struct ElementPicker: View {
    @EnvironmentObject private var viewModel: AmedasMapViewModel

    var body: some View {
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
    @EnvironmentObject private var viewModel: AmedasMapViewModel

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
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @Environment(\.scenePhase) private var phase
    @EnvironmentObject private var viewModel: AmedasMapViewModel

    var body: some View {
        ZStack {
            MapView()
                .edgesIgnoringSafeArea(.all)
                  
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
        .alert(isPresented: $viewModel.hasError) {
            // エラー時にはAlertを表示する
            Alert(title: Text(viewModel.errorMessage))
        }
        .onChange(of: phase) { newPhase in
            if newPhase == .active {
                LOG("scenePhase changed ACTIVE!!")
                viewModel.reload()
            }
        }
    }
}
