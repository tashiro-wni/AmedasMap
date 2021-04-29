//
//  ContentView.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/02.
//

import SwiftUI

private extension AmedasElement {
    var image: Image {
        switch self {
        case .temperature:    return Image(systemName: "thermometer")
        case .precipitation:  return Image(systemName: "cloud.rain")
        case .wind:           return Image(systemName: "wind")
        case .sun:            return Image(systemName: "sun.max")
        case .humidity:       return Image(systemName: "drop")
        }
    }
}

struct ContentView: View {
    @StateObject var viewModel = AmedasMapViewModel()

    var body: some View {
        ZStack {
            MapView(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
                        
            HStack {
                // データの時刻
                Text(viewModel.dateText)

                // 表示要素を選択
                Picker(selection: $viewModel.displayElement, label: EmptyView()) {
                    ForEach(AmedasElement.allCases, id: \.self) { element in
                        element.image
                    }                    
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 250)
                
                // 再読み込み
                Button(action: {
                    viewModel.loadData()
                }, label: {
                    Image(systemName: "gobackward")
                        .resizable()
                        .padding(8)
                        .frame(width: 30, height: 30)
                        .background(Color.white)
                        .cornerRadius(4)
                })
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(24)
        }
        .alert(isPresented: $viewModel.hasError) {
            // エラー時にはAlertを表示する
            Alert(title: Text(viewModel.errorMessage))
        }
    }
}
