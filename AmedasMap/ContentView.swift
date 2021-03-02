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
            Text(viewModel.dateText)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(24)
            Button(action: {
                viewModel.displayElement = viewModel.displayElement.next()
                //viewModel.loadData()
            }, label: {
                Image(systemName: "gobackward")
                    .frame(width: 40, height: 40)
                    .background(Color.white)
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(24)


        }
    }
}
