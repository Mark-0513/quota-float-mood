import Foundation
import XCTest

final class QuotaThemeSystemAdaptationTests: XCTestCase {
    func testThemeRootsUseExplicitSurfacesWithoutMaterialOrBlur() throws {
        let themesDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("src-macos-widget/Views/Themes", isDirectory: true)
        let themes: [(file: String, surfaceMarkers: [String])] = [
            (
                "PixelQuotaView.swift",
                [".containerBackground(Color(red: 0.055, green: 0.065, blue: 0.10), for: .widget)"]
            ),
            (
                "TerminalQuotaView.swift",
                [".containerBackground(Color(red: 0.012, green: 0.035, blue: 0.022), for: .widget)"]
            ),
            (
                "VaultQuotaView.swift",
                [
                    ".containerBackground(VaultPalette.background, for: .widget)",
                    "static let background = Color(red: 0.055, green: 0.044, blue: 0.028)"
                ]
            ),
            (
                "BlackGoldQuotaView.swift",
                [
                    ".containerBackground(BlackGoldPalette.background, for: .widget)",
                    "static let background = Color(red: 0.035, green: 0.034, blue: 0.032)"
                ]
            ),
            (
                "StickerQuotaView.swift",
                [
                    ".containerBackground(StickerPalette.silver, for: .widget)",
                    "static let silver = Color(red: 0.72, green: 0.75, blue: 0.78)"
                ]
            ),
            (
                "ProudBotQuotaView.swift",
                [
                    ".containerBackground(ProudBotPalette.background, for: .widget)",
                    "static let background = Color(red: 0.035, green: 0.055, blue: 0.10)"
                ]
            )
        ]
        let forbiddenEffects = [
            ".ultraThinMaterial",
            ".thinMaterial",
            ".regularMaterial",
            ".thickMaterial",
            ".ultraThickMaterial",
            ".blur("
        ]

        for theme in themes {
            let sourceURL = themesDirectory.appendingPathComponent(theme.file)
            let source = try String(contentsOf: sourceURL, encoding: .utf8)

            for marker in theme.surfaceMarkers {
                XCTAssertTrue(
                    source.contains(marker),
                    "\(theme.file) must keep its text-bearing widget surface explicit and opaque"
                )
            }
            for effect in forbiddenEffects {
                XCTAssertFalse(
                    source.contains(effect),
                    "\(theme.file) must not make readable content depend on \(effect)"
                )
            }
        }
    }
}
