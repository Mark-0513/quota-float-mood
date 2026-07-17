import SwiftUI
import WidgetKit

@main
struct QuotaFloatWidgetBundle: WidgetBundle {
    var body: some Widget {
        PixelQuotaWidget()
        TerminalQuotaWidget()
        VaultQuotaWidget()
        BlackGoldQuotaWidget()
        StickerQuotaWidget()
        ProudBotQuotaWidget()
    }
}

struct PixelQuotaWidget: Widget {
    private let kind = "QuotaFloatPixelWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuotaTimelineProvider()) { entry in
            PixelQuotaView(model: entry.model)
        }
        .configurationDisplayName("像素闯关机")
        .description("用像素生命值查看 Codex 额度。")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct TerminalQuotaWidget: Widget {
    private let kind = "QuotaFloatTerminalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuotaTimelineProvider()) { entry in
            TerminalQuotaView(model: entry.model)
        }
        .configurationDisplayName("赛博终端")
        .description("用系统核心读数查看 Codex 额度。")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct VaultQuotaWidget: Widget {
    private let kind = "QuotaFloatVaultWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuotaTimelineProvider()) { entry in
            VaultQuotaView(model: entry.model)
        }
        .configurationDisplayName("财富金库")
        .description("用金库储备查看 Codex 额度。")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct BlackGoldQuotaWidget: Widget {
    private let kind = "QuotaFloatBlackGoldWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuotaTimelineProvider()) { entry in
            BlackGoldQuotaView(model: entry.model)
        }
        .configurationDisplayName("黑金俱乐部")
        .description("用会员尊贵值查看 Codex 额度。")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct StickerQuotaWidget: Widget {
    private let kind = "QuotaFloatStickerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuotaTimelineProvider()) { entry in
            StickerQuotaView(model: entry.model)
        }
        .configurationDisplayName("潮玩贴纸")
        .description("用潮玩状态贴纸查看 Codex 额度。")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct ProudBotQuotaWidget: Widget {
    private let kind = "QuotaFloatProudBotWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuotaTimelineProvider()) { entry in
            ProudBotQuotaView(model: entry.model)
        }
        .configurationDisplayName("傲娇机器人")
        .description("用机器人核心电量查看 Codex 额度。")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
