import XCTest

final class QuotaThemeCopyTests: XCTestCase {
    func testPixelCopyTable() {
        XCTAssertEqual(QuotaThemeID.pixel.copy(for: .abundant).headline, "满血嚣张")
        XCTAssertEqual(QuotaThemeID.pixel.copy(for: .steady).headline, "稳定发育")
        XCTAssertEqual(QuotaThemeID.pixel.copy(for: .tense).headline, "残血别浪")
        XCTAssertEqual(QuotaThemeID.pixel.copy(for: .critical).headline, "最后一命")
        XCTAssertEqual(QuotaThemeID.pixel.copy(for: .unavailable).headline, "等待服务器")
    }

    func testTerminalCopyTable() {
        XCTAssertEqual(QuotaThemeID.terminal.copy(for: .abundant).headline, "核心过载")
        XCTAssertEqual(QuotaThemeID.terminal.copy(for: .steady).headline, "系统稳定")
        XCTAssertEqual(QuotaThemeID.terminal.copy(for: .tense).headline, "性能降级")
        XCTAssertEqual(QuotaThemeID.terminal.copy(for: .critical).headline, "CORE CRITICAL")
        XCTAssertEqual(QuotaThemeID.terminal.copy(for: .unavailable).headline, "NO SIGNAL")
    }

    func testVaultCopyTable() {
        XCTAssertEqual(QuotaThemeID.vault.copy(for: .abundant).headline, "富得流油")
        XCTAssertEqual(QuotaThemeID.vault.copy(for: .steady).headline, "精打细算")
        XCTAssertEqual(QuotaThemeID.vault.copy(for: .tense).headline, "余额告急")
        XCTAssertEqual(QuotaThemeID.vault.copy(for: .critical).headline, "破产边缘")
        XCTAssertEqual(QuotaThemeID.vault.copy(for: .unavailable).headline, "等待入账")
    }

    func testBlackGoldCopyTable() {
        XCTAssertEqual(QuotaThemeID.blackGold.copy(for: .abundant).headline, "尊贵满格")
        XCTAssertEqual(QuotaThemeID.blackGold.copy(for: .steady).headline, "从容有度")
        XCTAssertEqual(QuotaThemeID.blackGold.copy(for: .tense).headline, "体面告急")
        XCTAssertEqual(QuotaThemeID.blackGold.copy(for: .critical).headline, "尊贵值见底")
        XCTAssertEqual(QuotaThemeID.blackGold.copy(for: .unavailable).headline, "账单未到")
    }

    func testStickerCopyTable() {
        XCTAssertEqual(QuotaThemeID.sticker.copy(for: .abundant).headline, "状态超棒")
        XCTAssertEqual(QuotaThemeID.sticker.copy(for: .steady).headline, "认真营业")
        XCTAssertEqual(QuotaThemeID.sticker.copy(for: .tense).headline, "开始慌了")
        XCTAssertEqual(QuotaThemeID.sticker.copy(for: .critical).headline, "我真的没了")
        XCTAssertEqual(QuotaThemeID.sticker.copy(for: .unavailable).headline, "信号走丢了")
    }

    func testProudBotCopyTable() {
        XCTAssertEqual(QuotaThemeID.proudBot.copy(for: .abundant).headline, "我能打十个")
        XCTAssertEqual(QuotaThemeID.proudBot.copy(for: .steady).headline, "还能撑住")
        XCTAssertEqual(QuotaThemeID.proudBot.copy(for: .tense).headline, "低电但嘴硬")
        XCTAssertEqual(QuotaThemeID.proudBot.copy(for: .critical).headline, "求你充电")
        XCTAssertEqual(QuotaThemeID.proudBot.copy(for: .unavailable).headline, "雷达未回传")
    }

    func testProudBotEmptyCopyMatchesUnavailableHeadline() {
        XCTAssertEqual(QuotaThemeID.proudBot.emptyCopy, "雷达未回传")
    }
}
