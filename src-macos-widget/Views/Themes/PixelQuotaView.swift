import SwiftUI

struct PixelQuotaView: View {
    let model: QuotaDisplayModel

    var body: some View {
        Text(QuotaFormatter.percent(model.short.remainingPercent ?? model.weekly.remainingPercent))
            .containerBackground(.black, for: .widget)
    }
}
