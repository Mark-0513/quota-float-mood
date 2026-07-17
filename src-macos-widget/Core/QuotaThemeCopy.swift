import Foundation

struct ThemeMoodCopy: Equatable {
    let headline: String
    let detail: String
}

enum QuotaThemeID: String, CaseIterable {
    case pixel
    case terminal
    case vault
    case blackGold
    case sticker
    case proudBot

    func copy(for mood: QuotaMood) -> ThemeMoodCopy {
        switch self {
        case .pixel:
            switch mood {
            case .abundant: return ThemeMoodCopy(headline: "满血嚣张", detail: "能量槽满格")
            case .steady: return ThemeMoodCopy(headline: "稳定发育", detail: "稳住再升级")
            case .tense: return ThemeMoodCopy(headline: "残血别浪", detail: "省点血量")
            case .critical: return ThemeMoodCopy(headline: "最后一命", detail: "护住最后一格")
            case .unavailable: return ThemeMoodCopy(headline: "等待服务器", detail: "同步进度中")
            }
        case .terminal:
            switch mood {
            case .abundant: return ThemeMoodCopy(headline: "核心过载", detail: "ENERGY BUFFER FULL")
            case .steady: return ThemeMoodCopy(headline: "系统稳定", detail: "SYSTEM NOMINAL")
            case .tense: return ThemeMoodCopy(headline: "性能降级", detail: "THROTTLING ACTIVE")
            case .critical: return ThemeMoodCopy(headline: "CORE CRITICAL", detail: "POWER RESERVE LOW")
            case .unavailable: return ThemeMoodCopy(headline: "NO SIGNAL", detail: "AWAITING SYNC")
            }
        case .vault:
            switch mood {
            case .abundant: return ThemeMoodCopy(headline: "富得流油", detail: "金库储备充足")
            case .steady: return ThemeMoodCopy(headline: "精打细算", detail: "账本稳稳当当")
            case .tense: return ThemeMoodCopy(headline: "余额告急", detail: "先收紧开销")
            case .critical: return ThemeMoodCopy(headline: "破产边缘", detail: "守住最后储备")
            case .unavailable: return ThemeMoodCopy(headline: "等待入账", detail: "账本同步中")
            }
        case .blackGold:
            switch mood {
            case .abundant: return ThemeMoodCopy(headline: "尊贵满格", detail: "会员储备充盈")
            case .steady: return ThemeMoodCopy(headline: "从容有度", detail: "配额从容可用")
            case .tense: return ThemeMoodCopy(headline: "体面告急", detail: "请克制支出")
            case .critical: return ThemeMoodCopy(headline: "尊贵值见底", detail: "优先保留额度")
            case .unavailable: return ThemeMoodCopy(headline: "账单未到", detail: "账单同步中")
            }
        case .sticker:
            switch mood {
            case .abundant: return ThemeMoodCopy(headline: "状态超棒", detail: "今天照样开冲")
            case .steady: return ThemeMoodCopy(headline: "认真营业", detail: "节奏拿捏住")
            case .tense: return ThemeMoodCopy(headline: "开始慌了", detail: "先省着点用")
            case .critical: return ThemeMoodCopy(headline: "我真的没了", detail: "快去补点能量")
            case .unavailable: return ThemeMoodCopy(headline: "信号走丢了", detail: "正在找回信号")
            }
        case .proudBot:
            switch mood {
            case .abundant: return ThemeMoodCopy(headline: "我能打十个", detail: "核心电量拉满")
            case .steady: return ThemeMoodCopy(headline: "还能撑住", detail: "本机还能运行")
            case .tense: return ThemeMoodCopy(headline: "低电但嘴硬", detail: "别看我冒汗")
            case .critical: return ThemeMoodCopy(headline: "求你充电", detail: "需要一点充能")
            case .unavailable: return ThemeMoodCopy(headline: "雷达未回传", detail: "正在扫描信号")
            }
        }
    }

    var emptyCopy: String {
        copy(for: .unavailable).headline
    }
}
