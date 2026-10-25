import Foundation
import SwiftUI

enum AppLang: String { case ar, en }

enum L10n {
    static var lang: AppLang {
        if let forced = UserDefaults.standard.string(forKey: "forceLang") {
            return AppLang(rawValue: forced) ?? .ar
        }
        let code = Locale.preferredLanguages.first ?? "ar"
        return code.hasPrefix("ar") ? .ar : .en
    }
    static func t(_ ar: String, _ en: String) -> String { lang == .ar ? ar : en }
}

func L(_ ar: String, _ en: String) -> String { L10n.t(ar, en) }

extension View {
    func amanLayout() -> some View {
        environment(\.layoutDirection, L10n.lang == .ar ? .rightToLeft : .leftToRight)
    }
}
