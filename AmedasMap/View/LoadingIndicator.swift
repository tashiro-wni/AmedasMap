//
//  LoadingIndicator.swift
//  AmedasMap
//
//  Created by tasshy on 2024/07/04.
//

import SwiftUI

struct LoadingIndicator: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .padding()
            .tint(.white)
            .background(Color.black.opacity(0.5))
            .cornerRadius(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
