//
//  LoadingIndicator.swift
//  AmedasMap
//
//  Created by tasshy on 2024/07/04.
//

import SwiftUI

struct LoadingIndicator: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .padding()
            .tint(.white)
            .background(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.black.opacity(0.5))
            .cornerRadius(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
