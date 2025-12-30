//
//  sevgilimWidget.swift
//  sevgilimWidget
//
//  Neon Heart Theme Day Counter Widget
//

import WidgetKit
import SwiftUI

// MARK: - Data Provider
struct DayCounterProvider: TimelineProvider {
    
    private let appGroupId = "group.com.sevgilim.shared"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }
    
    func placeholder(in context: Context) -> DayCounterEntry {
        DayCounterEntry(
            date: Date(),
            daysTogether: 547,
            user1Name: "Sen",
            user2Name: "Sevgilin"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DayCounterEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DayCounterEntry>) -> Void) {
        let entry = createEntry()
        
        // Update at midnight
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
    
    private func createEntry() -> DayCounterEntry {
        let defaults = sharedDefaults
        
        let startDate = defaults?.object(forKey: "relationship_start_date") as? Date ?? Date()
        let user1Name = defaults?.string(forKey: "user1_name") ?? "Sen"
        let user2Name = defaults?.string(forKey: "user2_name") ?? "Sevgilin"
        
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        
        return DayCounterEntry(
            date: Date(),
            daysTogether: max(0, days),
            user1Name: user1Name,
            user2Name: user2Name
        )
    }
}

// MARK: - Entry
struct DayCounterEntry: TimelineEntry {
    let date: Date
    let daysTogether: Int
    let user1Name: String
    let user2Name: String
}

// MARK: - Neon Heart Widget View
struct DayCounterWidgetView: View {
    var entry: DayCounterEntry
    @Environment(\.widgetFamily) var family
    
    // Dark radial gradient like HeartView
    private var bgGradient: RadialGradient {
        RadialGradient(
            gradient: Gradient(colors: [
                Color(red: 0.15, green: 0.05, blue: 0.2),
                Color(red: 0.08, green: 0.02, blue: 0.12),
                Color.black
            ]),
            center: .center,
            startRadius: 5,
            endRadius: family == .systemSmall ? 120 : 200
        )
    }
    
    var body: some View {
        ZStack {
            // Dark gradient background - edge to edge
            bgGradient
            
            if family == .systemSmall {
                // SMALL WIDGET - Vertical layout (unchanged)
                smallWidgetContent
            } else {
                // MEDIUM WIDGET - Horizontal layout
                mediumWidgetContent
            }
        }
    }
    
    // MARK: - Small Widget Content (unchanged)
    private var smallWidgetContent: some View {
        VStack(spacing: 4) {
            neonHeart
            neonDaysCounter(size: 38)
            
            HStack(spacing: 3) {
                Text("gün birlikte")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                Text("💕")
                    .font(.system(size: 9))
            }
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding(8)
    }
    
    // MARK: - Medium Widget Content (NEW horizontal layout)
    private var mediumWidgetContent: some View {
        HStack(spacing: 0) {
            // LEFT SIDE - Big Neon Heart
            ZStack {
                // Outer glow
                Image(systemName: "heart.fill")
                    .font(.system(size: 65))
                    .foregroundStyle(Color.pink)
                    .blur(radius: 20)
                    .opacity(0.5)
                
                // Mid glow
                Image(systemName: "heart.fill")
                    .font(.system(size: 65))
                    .foregroundStyle(Color.pink)
                    .blur(radius: 10)
                    .opacity(0.4)
                
                // Main heart
                Image(systemName: "heart.fill")
                    .font(.system(size: 65))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.2, blue: 0.6),
                                Color(red: 0.8, green: 0.1, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .pink.opacity(0.8), radius: 10, x: 0, y: 0)
                
                // Inner highlight
                Image(systemName: "heart.fill")
                    .font(.system(size: 65))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .mask(
                        Image(systemName: "heart.fill")
                            .font(.system(size: 48))
                            .offset(y: 3)
                    )
                    .blendMode(.overlay)
            }
            .frame(maxWidth: .infinity)
            
            // RIGHT SIDE - Day Counter + Text
            VStack(spacing: 4) {
                // Neon number
                neonDaysCounter(size: 44)
                
                // Subtitle
                HStack(spacing: 3) {
                    Text("gün birlikte")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                    Text("💕")
                        .font(.system(size: 10))
                }
                .foregroundStyle(.white.opacity(0.85))
                
                // Names pill
                namesGlassPill
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Neon Heart
    private var neonHeart: some View {
        ZStack {
            // Outer glow
            Image(systemName: "heart.fill")
                .font(.system(size: family == .systemSmall ? 28 : 40))
                .foregroundStyle(Color.pink)
                .blur(radius: 15)
                .opacity(0.6)
            
            // Mid glow
            Image(systemName: "heart.fill")
                .font(.system(size: family == .systemSmall ? 28 : 40))
                .foregroundStyle(Color.pink)
                .blur(radius: 8)
                .opacity(0.4)
            
            // Main heart with neon gradient
            Image(systemName: "heart.fill")
                .font(.system(size: family == .systemSmall ? 28 : 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.2, blue: 0.6),
                            Color(red: 0.8, green: 0.1, blue: 0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .pink.opacity(0.8), radius: 8, x: 0, y: 0)
            
            // Inner highlight
            Image(systemName: "heart.fill")
                .font(.system(size: family == .systemSmall ? 28 : 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .mask(
                    Image(systemName: "heart.fill")
                        .font(.system(size: family == .systemSmall ? 20 : 30))
                        .offset(y: 2)
                )
                .blendMode(.overlay)
        }
    }
    
    // MARK: - Neon Days Counter
    private func neonDaysCounter(size: CGFloat) -> some View {
        ZStack {
            // Outer text glow
            Text("\(entry.daysTogether)")
                .font(.system(size: size, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.pink)
                .blur(radius: 12)
                .opacity(0.5)
            
            // Main number with gradient
            Text("\(entry.daysTogether)")
                .font(.system(size: size, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .pink.opacity(0.5), radius: 4, x: 0, y: 0)
        }
    }
    
    // MARK: - Names Glass Pill
    private var namesGlassPill: some View {
        HStack(spacing: 6) {
            Text(entry.user1Name)
                .fontWeight(.semibold)
            
            Image(systemName: "heart.fill")
                .font(.system(size: 8))
                .foregroundStyle(
                    LinearGradient(colors: [.pink, .orange], startPoint: .top, endPoint: .bottom)
                )
            
            Text(entry.user2Name)
                .fontWeight(.semibold)
        }
        .font(.system(size: 11, design: .rounded))
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [.pink.opacity(0.5), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Widget Configuration
struct sevgilimWidget: Widget {
    let kind: String = "sevgilimWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DayCounterProvider()) { entry in
            if #available(iOS 17.0, *) {
                DayCounterWidgetView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color.black
                    }
            } else {
                DayCounterWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Gün Sayacı 💕")
        .description("Birlikte geçirdiğiniz günleri sayar")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    sevgilimWidget()
} timeline: {
    DayCounterEntry(date: .now, daysTogether: 547, user1Name: "Adil", user2Name: "Ayça")
}

#Preview(as: .systemMedium) {
    sevgilimWidget()
} timeline: {
    DayCounterEntry(date: .now, daysTogether: 547, user1Name: "Adil", user2Name: "Ayça")
}
