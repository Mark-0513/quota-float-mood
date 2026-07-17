import SwiftUI

struct StickerQuotaView: View {
    let model: QuotaDisplayModel

    var body: some View {
        Text(QuotaFormatter.percent(model.short.remainingPercent ?? model.weekly.remainingPercent))
            .containerBackground(.gray, for: .widget)
    }
}
