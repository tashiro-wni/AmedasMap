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
        }
    }
}

// MARK: - ElementPicker 表示要素を選択
private struct ElementPicker: View {
    @StateObject var viewModel: AmedasMapViewModel
    
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
    @StateObject var viewModel: AmedasMapViewModel

    var body: some View {
        HStack(spacing: 10) {
            // データの時刻
            Text(viewModel.dateText)
            
            // 再読み込みボタン
            Button(action: {
                viewModel.reload()
            }, label: {
                Image(systemName: "gobackward")
                    .resizable()
                    .padding(8)
                    .frame(width: 30, height: 30)
                    .background(Color.white)
                    .cornerRadius(4)
                    //.accessibilityLabel("再読み込み")
            })
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @Environment(\.scenePhase) private var phase
    @StateObject private var viewModel = AmedasMapViewModel()

    var body: some View {
        ZStack {
            MapView(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
                  
            GeometryReader { geometry in
                if geometry.size.width < 500 {
                    VStack {
                        // 時刻・再読み込みボタン
                        TimestampView(viewModel: viewModel)
                        
                        // 表示要素を選択
                        ElementPicker(viewModel: viewModel)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(24)
                } else {
                    HStack {
                        // 時刻・再読み込みボタン
                        TimestampView(viewModel: viewModel)
                        
                        // 表示要素を選択
                        ElementPicker(viewModel: viewModel)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(8)
                }
            }
        }
        .sheet(isPresented: $viewModel.showModal) {
            PointView(viewModel: viewModel, selectedElement: viewModel.displayElement)
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
