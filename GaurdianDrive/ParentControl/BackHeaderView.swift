//
//  BackHeaderView.swift
//  GaurdianDrive
//
//  Created by Antigravity on 04/02/26.
//

import SwiftUI

struct BackHeaderView: View {
    let action: () -> Void

    var body: some View {
        HStack {
            Button(action: action) {
                Image("ic_back_blue")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            .frame(width: 40, height: 40)
            // Leading padding 20 to match app design
            .padding(.leading, 20)

            Spacer()
        }
        .frame(height: 60)
        .background(Color.white)
    }
}
