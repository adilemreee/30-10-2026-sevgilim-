//
//  TabBarDesignPreviewPage.swift
//  sevgilim
//

import SwiftUI

struct TabBarDesignPreviewPage: View {
    @State private var selectedTab: TabBarDesignTab = .home
    @State private var selectedThemeName: String = AppTheme.romantic.name
    @State private var selectedVariant: TabBarPreviewVariant = .attachedClassic
    
    private let previewThemes: [AppTheme] = [.romantic, .rose, .sunset, .ocean, .midnight]
    
    private var selectedTheme: AppTheme {
        previewThemes.first(where: { $0.name == selectedThemeName }) ?? .romantic
    }
    
    private var bottomContentPadding: CGFloat {
        selectedVariant.isAttached ? 108 : 140
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AnimatedGradientBackground(theme: selectedTheme)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 14) {
                previewHeader
                variantSelector
                themeSelector
                selectedTabCard
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, bottomContentPadding)
            
            tabBarHost
                .ignoresSafeArea(edges: selectedVariant.isAttached ? .bottom : [])
        }
    }
    
    private var previewHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("10 Tabbar Tasarim Onizleme")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Tum eski stiller kaldirildi. Burada en az 10 adet, birbirinden farkli tabbar var.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.24), lineWidth: 0.8)
        }
    }
    
    private var variantSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TabBarPreviewVariant.allCases) { variant in
                    let isSelected = selectedVariant == variant
                    
                    Button {
                        selectedVariant = variant
                    } label: {
                        Text(variant.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(
                                        isSelected
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: [selectedTheme.primaryColor, selectedTheme.secondaryColor],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        : AnyShapeStyle(.white.opacity(0.14))
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    private var themeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(previewThemes, id: \.name) { theme in
                    let isSelected = selectedThemeName == theme.name
                    
                    Button {
                        selectedThemeName = theme.name
                    } label: {
                        Text(theme.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(
                                        isSelected
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: [theme.primaryColor, theme.secondaryColor],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        : AnyShapeStyle(.white.opacity(0.12))
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    private var selectedTabCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(selectedTab.title, systemImage: selectedTab.icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            
            Text("Aktif Stil: \(selectedVariant.title)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.88))
            
            Text(selectedVariant.note)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.83))
            
            Text(selectedTab.description)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 0.8)
        }
    }
    
    @ViewBuilder
    private var tabBarHost: some View {
        if selectedVariant.isAttached {
            currentTabBar
                .frame(maxWidth: .infinity)
        } else {
            currentTabBar
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
    }
    
    @ViewBuilder
    private var currentTabBar: some View {
        switch selectedVariant {
        case .attachedClassic:
            AttachedClassicTabBar(selectedTab: $selectedTab, theme: selectedTheme)
        case .floatingPill:
            FloatingPillTabBar(selectedTab: $selectedTab, theme: selectedTheme)
        case .centerFabCutout:
            CenterFabCutoutTabBar(selectedTab: $selectedTab, theme: selectedTheme)
        case .segmentedRail:
            SegmentedRailTabBar(selectedTab: $selectedTab, theme: selectedTheme)
        case .timelineNodes:
            TimelineNodesTabBar(selectedTab: $selectedTab, theme: selectedTheme)
        case .waveAttached:
            WaveAttachedTabBar(selectedTab: $selectedTab, theme: selectedTheme)
        case .tileBlocks:
            TileBlocksTabBar(selectedTab: $selectedTab, theme: selectedTheme)
        case .monoMinimal:
            MonoMinimalTabBar(selectedTab: $selectedTab, theme: selectedTheme)
        case .orbitCircles:
            OrbitCirclesTabBar(selectedTab: $selectedTab, theme: selectedTheme)
        case .neonUnderline:
            NeonUnderlineTabBar(selectedTab: $selectedTab, theme: selectedTheme)
        }
    }
}

private struct AttachedClassicTabBar: View {
    @Binding var selectedTab: TabBarDesignTab
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(height: 0.8)
            
            HStack(spacing: 0) {
                ForEach(TabBarDesignTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    
                    Button {
                        HapticManager.shared.selection()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text(tab.shortTitle)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.76))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.primaryColor, theme.secondaryColor],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
        }
    }
}

private struct FloatingPillTabBar: View {
    @Binding var selectedTab: TabBarDesignTab
    let theme: AppTheme
    @Namespace private var pillAnimation
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(TabBarDesignTab.allCases) { tab in
                let isSelected = selectedTab == tab
                
                Button {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 15, weight: .semibold))
                        
                        if isSelected {
                            Text(tab.shortTitle)
                                .font(.system(size: 12, weight: .semibold))
                                .fixedSize()
                        }
                    }
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.76))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [theme.primaryColor, theme.secondaryColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .matchedGeometryEffect(id: "pill", in: pillAnimation)
                                .shadow(color: theme.primaryColor.opacity(0.38), radius: 8, x: 0, y: 5)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.22), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.16), radius: 14, x: 0, y: 8)
        }
    }
}

private struct CenterFabCutoutTabBar: View {
    @Binding var selectedTab: TabBarDesignTab
    let theme: AppTheme
    
    private let leftTabs: [TabBarDesignTab] = [.home, .memories]
    private let rightTabs: [TabBarDesignTab] = [.notes, .profile]
    
    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                ForEach(leftTabs) { tab in
                    sideButton(tab)
                }
                
                Spacer(minLength: 76)
                
                ForEach(rightTabs) { tab in
                    sideButton(tab)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .background {
                CenterNotchShape(cornerRadius: 24, notchDepth: 18, notchHalfWidth: 38)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        CenterNotchShape(cornerRadius: 24, notchDepth: 18, notchHalfWidth: 38)
                            .stroke(.white.opacity(0.2), lineWidth: 0.8)
                    }
                    .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
            }
            
            Button {
                HapticManager.shared.selection()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                    selectedTab = .photos
                }
            } label: {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.primaryColor, theme.secondaryColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Image(systemName: TabBarDesignTab.photos.icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 58, height: 58)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(selectedTab == .photos ? 0.95 : 0.6), lineWidth: 1.8)
                    }
                    .shadow(color: theme.primaryColor.opacity(0.5), radius: 12, x: 0, y: 8)
                    
                    Text("Foto")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .buttonStyle(.plain)
            .offset(y: -24)
        }
        .padding(.top, 24)
    }
    
    private func sideButton(_ tab: TabBarDesignTab) -> some View {
        let isSelected = selectedTab == tab
        
        return Button {
            HapticManager.shared.selection()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(tab.shortTitle)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.76))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background {
                if isSelected {
                    Capsule()
                        .fill(.white.opacity(0.16))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SegmentedRailTabBar: View {
    @Binding var selectedTab: TabBarDesignTab
    let theme: AppTheme
    @Namespace private var segmentAnimation
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [theme.primaryColor.opacity(0.9), theme.secondaryColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .clipShape(Capsule())
            
            HStack(spacing: 6) {
                ForEach(TabBarDesignTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    
                    Button {
                        HapticManager.shared.selection()
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .semibold))
                            Text(tab.shortTitle)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.74))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.white.opacity(0.16))
                                    .matchedGeometryEffect(id: "segment", in: segmentAnimation)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.17), radius: 13, x: 0, y: 7)
        }
    }
}

private struct TimelineNodesTabBar: View {
    @Binding var selectedTab: TabBarDesignTab
    let theme: AppTheme
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(.white.opacity(0.25))
                .frame(height: 3)
                .padding(.horizontal, 26)
                .offset(y: -12)
            
            HStack(spacing: 0) {
                ForEach(TabBarDesignTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    
                    Button {
                        HapticManager.shared.selection()
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 7) {
                            Circle()
                                .fill(
                                    isSelected
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [theme.primaryColor, theme.secondaryColor],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    : AnyShapeStyle(.white.opacity(0.18))
                                )
                                .frame(width: isSelected ? 28 : 20, height: isSelected ? 28 : 20)
                                .overlay {
                                    if isSelected {
                                        Image(systemName: tab.icon)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .shadow(color: isSelected ? theme.primaryColor.opacity(0.45) : .clear, radius: 8, x: 0, y: 4)
                            
                            Text(tab.shortTitle)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(isSelected ? .white : .white.opacity(0.76))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.16), radius: 13, x: 0, y: 8)
        }
    }
}

private struct WaveAttachedTabBar: View {
    @Binding var selectedTab: TabBarDesignTab
    let theme: AppTheme
    
    var body: some View {
        ZStack(alignment: .top) {
            WaveTopShape(cornerRadius: 24, dipDepth: 14, dipHalfWidth: 54)
                .fill(.ultraThinMaterial)
                .overlay {
                    WaveTopShape(cornerRadius: 24, dipDepth: 14, dipHalfWidth: 54)
                        .stroke(.white.opacity(0.2), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 8)
            
            HStack(spacing: 0) {
                ForEach(TabBarDesignTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    
                    Button {
                        HapticManager.shared.selection()
                        withAnimation(.spring(response: 0.33, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .semibold))
                            Text(tab.shortTitle)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.75))
                        .offset(y: isSelected ? -7 : 0)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                        .padding(.bottom, 10)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.primaryColor.opacity(0.95), theme.secondaryColor.opacity(0.9)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
        .frame(height: 90)
    }
}

private struct TileBlocksTabBar: View {
    @Binding var selectedTab: TabBarDesignTab
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(TabBarDesignTab.allCases) { tab in
                let isSelected = selectedTab == tab
                
                Button {
                    HapticManager.shared.selection()
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: isSelected ? 17 : 15, weight: .semibold))
                        Text(tab.shortTitle)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.74))
                    .frame(maxWidth: .infinity)
                    .frame(height: isSelected ? 56 : 50)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [theme.primaryColor, theme.secondaryColor],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                : AnyShapeStyle(.white.opacity(0.12))
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(.white.opacity(isSelected ? 0.46 : 0.16), lineWidth: 0.9)
                            }
                            .shadow(color: isSelected ? theme.primaryColor.opacity(0.36) : .black.opacity(0.12), radius: isSelected ? 10 : 4, x: 0, y: 4)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.16), radius: 12, x: 0, y: 8)
        }
    }
}

private struct MonoMinimalTabBar: View {
    @Binding var selectedTab: TabBarDesignTab
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.white.opacity(0.18))
                .frame(height: 0.8)
            
            HStack(spacing: 0) {
                ForEach(TabBarDesignTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    
                    Button {
                        HapticManager.shared.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(tab.shortTitle.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                            
                            Circle()
                                .fill(
                                    isSelected
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [theme.primaryColor, theme.secondaryColor],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    : AnyShapeStyle(.clear)
                                )
                                .frame(width: 5, height: 5)
                        }
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.65))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(.ultraThinMaterial)
        }
    }
}

private struct OrbitCirclesTabBar: View {
    @Binding var selectedTab: TabBarDesignTab
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(TabBarDesignTab.allCases) { tab in
                let isSelected = selectedTab == tab
                
                Button {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.76)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .stroke(.white.opacity(0.26), lineWidth: 1)
                                .frame(width: 42, height: 42)
                            
                            Circle()
                                .fill(
                                    isSelected
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [theme.primaryColor, theme.secondaryColor],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    : AnyShapeStyle(.white.opacity(0.12))
                                )
                                .frame(width: isSelected ? 34 : 28, height: isSelected ? 34 : 28)
                            
                            Image(systemName: tab.icon)
                                .font(.system(size: isSelected ? 14 : 12, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        
                        Text(tab.shortTitle)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.75))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.16), radius: 12, x: 0, y: 8)
        }
    }
}

private struct NeonUnderlineTabBar: View {
    @Binding var selectedTab: TabBarDesignTab
    let theme: AppTheme
    @Namespace private var neonAnimation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabBarDesignTab.allCases) { tab in
                let isSelected = selectedTab == tab
                
                Button {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .semibold))
                        Text(tab.shortTitle)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.72))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .overlay(alignment: .bottom) {
                        if isSelected {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [theme.primaryColor, theme.secondaryColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 34, height: 3)
                                .matchedGeometryEffect(id: "neon-line", in: neonAnimation)
                                .shadow(color: theme.primaryColor.opacity(0.7), radius: 8, x: 0, y: 0)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.34))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.22), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.32), radius: 16, x: 0, y: 10)
        }
    }
}

private struct CenterNotchShape: Shape {
    var cornerRadius: CGFloat
    var notchDepth: CGFloat
    var notchHalfWidth: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let r = min(cornerRadius, min(rect.width, rect.height) / 2)
        let midX = rect.midX
        
        var path = Path()
        path.move(to: CGPoint(x: r, y: 0))
        
        path.addLine(to: CGPoint(x: midX - notchHalfWidth, y: 0))
        path.addCurve(
            to: CGPoint(x: midX + notchHalfWidth, y: 0),
            control1: CGPoint(x: midX - notchHalfWidth * 0.45, y: 0),
            control2: CGPoint(x: midX + notchHalfWidth * 0.45, y: notchDepth)
        )
        
        path.addLine(to: CGPoint(x: rect.width - r, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: r),
            control: CGPoint(x: rect.width, y: 0)
        )
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - r))
        path.addQuadCurve(
            to: CGPoint(x: rect.width - r, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )
        
        path.addLine(to: CGPoint(x: r, y: rect.height))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - r),
            control: CGPoint(x: 0, y: rect.height)
        )
        
        path.addLine(to: CGPoint(x: 0, y: r))
        path.addQuadCurve(
            to: CGPoint(x: r, y: 0),
            control: CGPoint(x: 0, y: 0)
        )
        
        path.closeSubpath()
        return path
    }
}

private struct WaveTopShape: Shape {
    var cornerRadius: CGFloat
    var dipDepth: CGFloat
    var dipHalfWidth: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let r = min(cornerRadius, min(rect.width, rect.height) / 2)
        let midX = rect.midX
        
        var path = Path()
        path.move(to: CGPoint(x: r, y: 0))
        
        path.addLine(to: CGPoint(x: midX - dipHalfWidth, y: 0))
        path.addCurve(
            to: CGPoint(x: midX + dipHalfWidth, y: 0),
            control1: CGPoint(x: midX - dipHalfWidth * 0.6, y: 0),
            control2: CGPoint(x: midX + dipHalfWidth * 0.6, y: dipDepth)
        )
        
        path.addLine(to: CGPoint(x: rect.width - r, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: r),
            control: CGPoint(x: rect.width, y: 0)
        )
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - r))
        path.addQuadCurve(
            to: CGPoint(x: rect.width - r, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )
        
        path.addLine(to: CGPoint(x: r, y: rect.height))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - r),
            control: CGPoint(x: 0, y: rect.height)
        )
        
        path.addLine(to: CGPoint(x: 0, y: r))
        path.addQuadCurve(
            to: CGPoint(x: r, y: 0),
            control: CGPoint(x: 0, y: 0)
        )
        
        path.closeSubpath()
        return path
    }
}

private enum TabBarPreviewVariant: String, CaseIterable, Identifiable {
    case attachedClassic
    case floatingPill
    case centerFabCutout
    case segmentedRail
    case timelineNodes
    case waveAttached
    case tileBlocks
    case monoMinimal
    case orbitCircles
    case neonUnderline
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .attachedClassic: "Attached Classic"
        case .floatingPill: "Floating Pill"
        case .centerFabCutout: "Center Fab Cutout"
        case .segmentedRail: "Segmented Rail"
        case .timelineNodes: "Timeline Nodes"
        case .waveAttached: "Wave Attached"
        case .tileBlocks: "Tile Blocks"
        case .monoMinimal: "Mono Minimal"
        case .orbitCircles: "Orbit Circles"
        case .neonUnderline: "Neon Underline"
        }
    }
    
    var note: String {
        switch self {
        case .attachedClassic:
            "Alt kenara yapisik, klasik ama modernlesmis gorunum."
        case .floatingPill:
            "Yumusak capsule zemin, secili oge kayan pill ile belirgin."
        case .centerFabCutout:
            "Ortada buyuk aksiyon butonu ve kesik notch taban."
        case .segmentedRail:
            "Segment gorunumu + ust rail ile daha teknik bir dil."
        case .timelineNodes:
            "Zaman cizgisi ustunde node mantigi ile gecisler."
        case .waveAttached:
            "Alt kenara yapisik, ustte dalga formuyla farkli siluet."
        case .tileBlocks:
            "Her sekme ayri karo/kutucuk gibi davranir."
        case .monoMinimal:
            "Ikon yok, sadece metin ve nokta ile super sade stil."
        case .orbitCircles:
            "Dairesel orbit hissi veren ikon halkalari."
        case .neonUnderline:
            "Koyu taban ustunde parlak cizgi vurgulu secim."
        }
    }
    
    var isAttached: Bool {
        switch self {
        case .attachedClassic, .waveAttached, .monoMinimal:
            true
        default:
            false
        }
    }
}

private enum TabBarDesignTab: Int, CaseIterable, Identifiable {
    case home, memories, photos, notes, profile
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .home: "Ana Sayfa"
        case .memories: "Anilar"
        case .photos: "Fotograflar"
        case .notes: "Notlar"
        case .profile: "Profil"
        }
    }
    
    var shortTitle: String {
        switch self {
        case .home: "Ana"
        case .memories: "Ani"
        case .photos: "Foto"
        case .notes: "Not"
        case .profile: "Ben"
        }
    }
    
    var icon: String {
        switch self {
        case .home: "house.fill"
        case .memories: "heart.fill"
        case .photos: "photo.fill"
        case .notes: "note.text"
        case .profile: "person.fill"
        }
    }
    
    var description: String {
        switch self {
        case .home:
            "Iliski ozeti ve hizli ulasimlar."
        case .memories:
            "Birlikteki ozel anlarin zamani."
        case .photos:
            "Medya merkezi ve galeriler."
        case .notes:
            "Notlar, fikirler ve planlar."
        case .profile:
            "Kisisel ayarlar ve tema secimi."
        }
    }
}

#Preview("Tabbar Tasarimlari") {
    TabBarDesignPreviewPage()
}
