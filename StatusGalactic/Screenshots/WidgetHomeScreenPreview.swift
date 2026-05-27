import SwiftUI

/// Faux home-screen render of the medium widget. Used **only** for the
/// shot 11 marketing capture — XCUITest can't drive SpringBoard, so we
/// can't take a real home-screen screenshot with the widget placed.
/// This view stands in by rendering `BriefWidgetView` at the actual
/// medium-widget point size (170 × 358 on the 6.9" canvas) on a dark
/// home-screen-shaped background. The end result reads as
/// "home screen with widget" in the App Store gallery.
///
/// Active only when launched with both `-UITEST_SCREENSHOT_MODE` and
/// `-UITEST_WIDGET_PREVIEW`. Everything else in the app behaves
/// normally.
struct WidgetHomeScreenPreview: View {

    /// Keep in sync with `ScreenshotTests.test_11_widget`.
    static let launchArgument = "-UITEST_WIDGET_PREVIEW"

    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    let entry: BriefWidgetEntry

    var body: some View {
        ZStack {
            // Vertical gradient mimicking iOS dark wallpaper.
            LinearGradient(
                colors: [
                    GalacticPalette.cosmicBlack,
                    GalacticPalette.deepPurple,
                    GalacticPalette.cosmicBlack
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Cheap starfield so the empty background doesn't feel flat.
            HomeScreenStarfield()
                .opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // The widget itself — rendered at native medium-widget
                // aspect with the standard 22pt corner radius. We
                // instantiate `MediumView` directly because WidgetKit's
                // `\.widgetFamily` environment key isn't writable from
                // outside the widget bundle. The `.containerBackground`
                // that iOS would normally apply is replaced here by a
                // matching dark fill so SF Symbols sit readable on the
                // home-screen wallpaper.
                MediumView(entry: entry)
                    .frame(width: 364, height: 170)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(.black.opacity(0.55))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: .black.opacity(0.4), radius: 18, y: 6)

                // A row of placeholder app dots underneath the widget
                // so the gallery still reads as "this is a home
                // screen" rather than "this is a floating widget."
                HStack(spacing: 26) {
                    ForEach(0..<4, id: \.self) { _ in
                        Circle()
                            .fill(.white.opacity(0.08))
                            .frame(width: 56, height: 56)
                    }
                }
                .opacity(0.7)
            }
            .padding(.bottom, 80)
        }
    }
}

/// Local lightweight starfield — kept separate from the moon hero's
/// because that one is sized to its own square frame, and we want full
/// screen coverage here.
private struct HomeScreenStarfield: View {
    var body: some View {
        Canvas { ctx, size in
            var seed: UInt64 = 0x9E3779B97F4A7C15
            func step() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double(seed >> 11) / Double(1 << 53)
            }
            for _ in 0..<160 {
                let x = step() * size.width
                let y = step() * size.height
                let r = 0.5 + step() * 1.8
                let alpha = 0.18 + step() * 0.6
                let rect = CGRect(x: x, y: y, width: r, height: r)
                ctx.fill(Path(ellipseIn: rect),
                         with: .color(.white.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
    }
}
