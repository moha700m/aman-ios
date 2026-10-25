import Foundation

struct CatalogChecklistItem: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var ar: String
    var en: String
    var title: String { L(ar, en) }
}

struct CatalogChecklist: Codable, Identifiable, Equatable {
    var id: String
    var ar: String
    var en: String
    var items: [CatalogChecklistItem]
    var title: String { L(ar, en) }
}

struct CatalogTip: Codable, Equatable {
    var ar: String
    var en: String
    var text: String { L(ar, en) }
}

struct CatalogThresholds: Codable, Equatable {
    var magnetSpikeQuick: Double
    var magnetSpikeBalanced: Double
    var magnetSpikeThorough: Double
    var magnetHysteresis: Double
    var magnetWarmupSeconds: Double
    var magnetBaselineSamples: Int
    var magnetConsecutiveHits: Int
    var bleStrongRSSI: Int
    var bleMediumRSSI: Int
    var lensLumaThreshold: Double
    var lensMinCluster: Int
    var lensMaxCluster: Int
    var lensMinFill: Double
}

struct Catalog: Codable, Equatable {
    var version: Int
    var disclaimerAr: String
    var disclaimerEn: String
    var thresholds: CatalogThresholds
    var checklists: [CatalogChecklist]
    var tips: [CatalogTip]
    var hidingSpotsAr: [String]
    var hidingSpotsEn: [String]
    var rfTips: [CatalogTip]? = nil
    var wifiTips: [CatalogTip]? = nil
    var privacyTips: [CatalogTip]? = nil
    var guidedSteps: [CatalogTip]? = nil

    var tipOfDay: CatalogTip? {
        guard !tips.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return tips[day % tips.count]
    }
    var rf: [CatalogTip] { rfTips ?? Catalog.defaultRF }
    var wifi: [CatalogTip] { wifiTips ?? Catalog.defaultWiFi }
    var privacy: [CatalogTip] { privacyTips ?? Catalog.defaultPrivacy }
    var steps: [CatalogTip] { guidedSteps ?? Catalog.defaultSteps }

    static let defaultRF: [CatalogTip] = [
        .init(ar: "الجوال ما يقدر يقيس ترددات الراديو مباشرة — أي تطبيق يقول كذا يبالغ.", en: "Phones can't measure RF directly — apps claiming that overstate."),
        .init(ar: "افصل الأجهزة غير الضرورية (شاحن، ساعة) وشوف إذا فيها ضوء أو فتحة صغيرة.", en: "Unplug non-essential gadgets (chargers, clocks) and check for tiny holes or LEDs."),
        .init(ar: "الأجهزة اللي تبث بلوتوث تظهر بقائمة البلوتوث — راجعها بعد ما تطفي أجهزتك.", en: "BLE-broadcasting devices show in the Bluetooth list — review it after turning off your own gear."),
        .init(ar: "الكاميرا المسجلة على كرت ذاكرة ما تبث شي — الفحص البصري هو الأهم.", en: "SD-card cameras broadcast nothing — visual inspection matters most.")]
    static let defaultWiFi: [CatalogTip] = [
        .init(ar: "اسأل المضيف عن عدد الأجهزة المتصلة بالراوتر وأسمائها.", en: "Ask the host how many devices are on the router and what they are."),
        .init(ar: "أسماء شبكات مثل IPCAM أو 'cam' أو أرقام غريبة تستاهل سؤال.", en: "Network names like IPCAM, 'cam' or odd numbers are worth asking about."),
        .init(ar: "تطبيق الراوتر (إن أعطاك المضيف الصلاحية) يعرض كل الأجهزة.", en: "The router app (if the host allows) lists every connected device."),
        .init(ar: "iOS ما يسمح للتطبيقات تمسح كل أجهزة الشبكة — لذلك ما نعرضها.", en: "iOS doesn't let apps list every network device — so we don't pretend to.")]
    static let defaultPrivacy: [CatalogTip] = [
        .init(ar: "غطِّ أي عدسة مشكوك فيها بشريط أو قماش.", en: "Cover any suspicious lens with tape or cloth."),
        .init(ar: "وجّه الشواحن والساعات بعيد عن السرير والحمام.", en: "Turn chargers and clocks away from the bed and bathroom."),
        .init(ar: "تأكد إن المرايا ما فيها فراغ خلفها (قرّب إصبعك: فراغ = مرآة عادية بعيدة).", en: "Check mirrors: a gap between finger and reflection usually means a normal mirror."),
        .init(ar: "إذا لقيت شي فعلي: صوّره، لا تلمسه، وبلّغ الجهات المختصة.", en: "If you find something real: photograph it, don't touch it, and report it.")]
    static let defaultSteps: [CatalogTip] = [
        .init(ar: "١. أطفِ أجهزتك اللي تبث بلوتوث (سماعات، ساعة).", en: "1. Turn off your own Bluetooth gear (earbuds, watch)."),
        .init(ar: "٢. امسح البلوتوث دقيقة وانتبه للمتتبعات.", en: "2. Scan Bluetooth for a minute and watch for trackers."),
        .init(ar: "٣. مرّر المغناطيس على الشواحن والساعات والدخان.", en: "3. Sweep the magnetometer over chargers, clocks, smoke detectors."),
        .init(ar: "٤. أطفِ النور وافحص اللمعة بالفلاش ببطء.", en: "4. Lights off, sweep slowly for glints with the torch."),
        .init(ar: "٥. كمّل قائمة الغرفة وصدّر التقرير.", en: "5. Finish the room checklist and export the report.")]

    static let remoteURL = URL(string: "https://moha700m.github.io/aman-ios/catalog.json")!

    var disclaimer: String { L(disclaimerAr, disclaimerEn) }
    var hidingSpots: [String] { L10n.lang == .ar ? hidingSpotsAr : hidingSpotsEn }

    static var bundled: Catalog {
        Catalog(
            version: 1,
            disclaimerAr: "فحص مساعد — ما يضمن كشف كل الكاميرات أو أجهزة التتبع، وما يستبدل معدات احترافية.",
            disclaimerEn: "Helper check — does not guarantee detecting every camera or tracker, and does not replace professional equipment.",
            thresholds: CatalogThresholds(
                magnetSpikeQuick: 22, magnetSpikeBalanced: 18, magnetSpikeThorough: 12,
                magnetHysteresis: 8, magnetWarmupSeconds: 1.5, magnetBaselineSamples: 40,
                magnetConsecutiveHits: 3, bleStrongRSSI: -50, bleMediumRSSI: -70,
                lensLumaThreshold: 0.96, lensMinCluster: 2, lensMaxCluster: 80, lensMinFill: 0.45
            ),
            checklists: [
                CatalogChecklist(id: "chalet", ar: "شاليه / استراحة", en: "Chalet / rest house", items: [
                    .init(id: "c1", ar: "سقف ودخان الحريق", en: "Ceiling & smoke detector"),
                    .init(id: "c2", ar: "ساعة المنبه والشاحن", en: "Alarm clock & charger"),
                    .init(id: "c3", ar: "مرايا الحمام", en: "Bathroom mirrors"),
                    .init(id: "c4", ar: "فتحات التكييف", en: "AC vents"),
                    .init(id: "c5", ar: "تحت السرير والطاولة", en: "Under bed & table"),
                    .init(id: "c6", ar: "تلفزيون والراوتر", en: "TV & router")
                ]),
                CatalogChecklist(id: "hotel", ar: "فندق", en: "Hotel", items: [
                    .init(id: "h1", ar: "ساعة ودولاب", en: "Clock & wardrobe"),
                    .init(id: "h2", ar: "مرايا ودش", en: "Mirrors & shower"),
                    .init(id: "h3", ar: "شاحن حائط وUSB", en: "Wall charger & USB"),
                    .init(id: "h4", ar: " downstreamان الحريق", en: "Smoke detector"),
                    .init(id: "h5", ar: "تحت السرير", en: "Under the bed")
                ]),
                CatalogChecklist(id: "fitting", ar: "غرفة قياس", en: "Fitting room", items: [
                    .init(id: "f1", ar: "مرايا بزوايا", en: "Angled mirrors"),
                    .init(id: "f2", ar: "خطاف وشنطة", en: "Hook & bag area"),
                    .init(id: "f3", ar: "سقف وإضاءة", en: "Ceiling & lights"),
                    .init(id: "f4", ar: "فتحات تهوية", en: "Vents")
                ])
            ],
            tips: [
                .init(ar: "حرّك الجوال ببطء قرب الجسم المشتبه — الارتفاع المفاجئ يستاهل نظرة بالعين.", en: "Move slowly near a suspect object — a sudden spike deserves a closer look."),
                .init(ar: "أطفي النور وفعّل الفلاش عشان تبان لمعة العدسة أوضح.", en: "Lights off and torch on makes lens glints easier to spot."),
                .init(ar: "جهاز البلوتوث القوي جدًا (−50 أو أعلى) غالبًا في نفس الغرفة.", en: "Very strong BLE (−50 or higher) is usually in the same room."),
                .init(ar: "المغنطيس يتأثر بالسماعات والمعدن — مو إثبات كاميرا.", en: "Magnetometer reacts to speakers and metal — not proof of a camera.")
            ],
            hidingSpotsAr: ["شاحن USB", "ساعة منبه", "دخان حريق", "تكييف", "مرآة", "ورد صناعي", "تلفزيون"],
            hidingSpotsEn: ["USB charger", "Alarm clock", "Smoke detector", "AC vent", "Mirror", "Fake plant", "TV"]
        )
    }
}

enum CatalogService {
    static var cacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("aman-catalog.json")
    }
    static func cached() -> Catalog? {
        (try? Data(contentsOf: cacheURL)).flatMap { try? JSONDecoder().decode(Catalog.self, from: $0) }
    }
    static func fetchRemote() async -> Catalog? {
        var r = URLRequest(url: Catalog.remoteURL)
        r.timeoutInterval = 8
        r.cachePolicy = .reloadIgnoringLocalCacheData
        guard let (data, resp) = try? await URLSession.shared.data(for: r),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let c = try? JSONDecoder().decode(Catalog.self, from: data) else { return nil }
        try? data.write(to: cacheURL)
        return c
    }
}
