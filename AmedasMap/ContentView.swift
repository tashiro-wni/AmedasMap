//
//  ContentView.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/02.
//

import SwiftUI

struct ContentView: View {
    @State var viewModel = AmedasMapViewModel()

    var body: some View {
        ZStack {
            MapView(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
                        
            HStack {
                // データの時刻
                Text(viewModel.dateText)

                // 表示要素を選択
                Picker(selection: $viewModel.displayElement, label: Spacer()) {
                    Image(systemName: "thermometer").tag(AmedasElement.temperature)
                    Image(systemName: "drop").tag(AmedasElement.precipitation)
                    Image(systemName: "wind").tag(AmedasElement.wind)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
                
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
            Alert(title: Text(viewModel.errorMessage ?? ""))
        }
    }
}
