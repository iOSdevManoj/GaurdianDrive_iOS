import DeviceActivity
import ManagedSettings
import SwiftUI

struct TotalActivityView: View {
    let appInfos: [SharedAppInfo]

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.appDarkBlue)
            Text("\(appInfos.count) apps resolved")
                .font(.headline)
                .foregroundStyle(.black)
            Text("Swipe down to close")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

extension Color {
    static let appDarkBlue = Color(red: 26 / 255, green: 48 / 255, blue: 97 / 255)
}
