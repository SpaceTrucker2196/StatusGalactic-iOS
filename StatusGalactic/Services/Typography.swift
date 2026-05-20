import SwiftUI

/// Fira Code monospaced typography, Dynamic-Type aware.
///
/// Use `.font(.firaCode(.body))` instead of `.font(.body)` across the app.
/// The `relativeTo:` parameter on `Font.custom(...)` makes the rendered size
/// scale with the user's iOS text-size setting.
extension Font {

    /// Fira Code at the size matching a system text style, scaling with
    /// Dynamic Type.
    static func firaCode(
        _ style: TextStyle,
        weight: Font.Weight = .regular
    ) -> Font {
        .custom(
            FiraCode.name(for: weight),
            size: FiraCode.baseSize(for: style),
            relativeTo: style
        )
    }

    /// Fira Code at a fixed point size (does not scale with Dynamic Type).
    /// Useful for big readout digits where layout depends on width.
    static func firaCodeFixed(
        size: CGFloat,
        weight: Font.Weight = .regular
    ) -> Font {
        .custom(FiraCode.name(for: weight), fixedSize: size)
    }
}

enum FiraCode {
    /// PostScript names. These must match the names baked into the TTF files,
    /// not the filenames. Confirmed against Fira Code 6.2 release.
    static func name(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light:   return "FiraCode-Light"
        case .medium:                       return "FiraCode-Medium"
        case .semibold:                     return "FiraCode-SemiBold"
        case .bold, .heavy, .black:         return "FiraCode-Bold"
        default:                            return "FiraCode-Regular"
        }
    }

    /// Base point sizes matching Apple's HIG defaults for each text style.
    /// Dynamic Type scales these up or down according to the user's setting.
    static func baseSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle:  return 34
        case .title:       return 28
        case .title2:      return 22
        case .title3:      return 20
        case .headline:    return 17
        case .body:        return 17
        case .callout:     return 16
        case .subheadline: return 15
        case .footnote:    return 13
        case .caption:     return 12
        case .caption2:    return 11
        @unknown default:  return 17
        }
    }
}
