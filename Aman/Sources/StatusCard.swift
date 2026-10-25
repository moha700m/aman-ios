import SwiftUI
import CoreBluetooth
import UIKit

enum SystemSettings {
    /// Opens this app's page in the real iOS Settings app.
    static func open() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

struct StatusCard: View {
    var symbol: String
    var title: String
    var message: String
    var showSettings = true
    var tint: Color = AmanTheme.warn

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: symbol).font(.title3).foregroundStyle(tint)
                Text(title).font(.headline).foregroundStyle(AmanTheme.ink)
            }
            Text(message).font(.subheadline).foregroundStyle(AmanTheme.ink.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            if showSettings {
                Button { SystemSettings.open() } label: {
                    Label(L("افتح إعدادات الآيفون", "Open iPhone Settings"), systemImage: "gearshape")
                        .font(.subheadline.weight(.bold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 46)
                        .background(AmanTheme.green, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard(18)
    }
}

struct BluetoothStateCard: View {
    var state: CBManagerState
    var body: some View {
        switch state {
        case .unauthorized:
            StatusCard(symbol: "hand.raised.fill",
                       title: L("إذن البلوتوث مقفل", "Bluetooth permission is off"),
                       message: L("افتح الإعدادات ← أمان الغرفة ← فعّل البلوتوث، وارجع للتطبيق.",
                                   "Open Settings → Aman Al-Ghurfa → enable Bluetooth, then come back."))
        case .poweredOff:
            StatusCard(symbol: "antenna.radiowaves.left.and.right.slash",
                       title: L("البلوتوث مطفي", "Bluetooth is off"),
                       message: L("شغّله من مركز التحكم (اسحب من أعلى اليمين) وبيبدأ المسح تلقائيًا.",
                                   "Turn it on from Control Center; scanning starts automatically."),
                       showSettings: false)
        case .unsupported:
            StatusCard(symbol: "xmark.octagon",
                       title: L("الجهاز ما يدعم بلوتوث LE", "Bluetooth LE not supported"),
                       message: L("جرّب الأدوات الثانية: المغناطيس والقائمة.", "Try the other tools: magnetometer and checklist."),
                       showSettings: false)
        default:
            EmptyView()
        }
    }
}
