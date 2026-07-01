import SwiftUI

/// 设计 token（见 style.md）。命名对应 CSS 变量。
enum Theme {
    // 背景层级
    static let bgApp = Color(hex: 0xF6F6FA)       // 应用背景
    static let bgSurface = Color(hex: 0xFFFFFF)   // 主内容/卡片
    static let bgSubtle = Color(hex: 0xF1F1F7)    // 输入框/代码块
    static let bgMuted = Color(hex: 0xE8E8F1)     // 选中列表/终端头

    // 边框
    static let border = Color(hex: 0xE3E4EC)
    static let borderStrong = Color(hex: 0xD4D7E2)

    // 文字
    static let textPrimary = Color(hex: 0x171923)
    static let textSecondary = Color(hex: 0x667085)
    static let textTertiary = Color(hex: 0x9AA1B5)
    static let textDisabled = Color(hex: 0xB8BDCC)

    // 品牌与状态
    static let primary = Color(hex: 0x3F7DED)
    static let primaryHover = Color(hex: 0x2F6FE4)
    static let primarySoft = Color(hex: 0xE8F0FF)
    static let success = Color(hex: 0x22C55E)
    static let successSoft = Color(hex: 0xEAF8EF)
    static let danger = Color(hex: 0xF05265)
    static let dangerSoft = Color(hex: 0xFFECEF)
    static let warning = Color(hex: 0xF5B301)

    // 间距 (pt)
    enum Spacing {
        static let xs: CGFloat = 2
        static let s2: CGFloat = 4
        static let s3: CGFloat = 6
        static let s4: CGFloat = 8
        static let s6: CGFloat = 12
        static let s7: CGFloat = 16
        static let s8: CGFloat = 20
        static let s9: CGFloat = 24
        static let s10: CGFloat = 32
    }

    // 圆角
    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 10
        static let xl: CGFloat = 12
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
