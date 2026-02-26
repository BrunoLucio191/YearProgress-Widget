import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Configuração de Layout
struct GridLayoutConfig {
    let columns: Int
    let spacing: CGFloat
    let dotSize: CGFloat
}

// MARK: - Configuração do Widget (App Intent)
struct YearWidgetConfigurationIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Widget Setting"
    static var description = IntentDescription("Customize the widget layout")
    @Parameter(title: "Show days info", default: false)
    var showDayInfo: Bool
}

// MARK: - Timeline Provider
struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: YearWidgetConfigurationIntent())
    }

    func snapshot(for configuration: YearWidgetConfigurationIntent, in context: Context) async -> SimpleEntry {
        let config = configuration
        config.showDayInfo = true
        return SimpleEntry(date: Date(), configuration: config)
    }

    func timeline(for configuration: YearWidgetConfigurationIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let currentDate = Date()
        let nextMidnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!)
        
       
        let entry = SimpleEntry(date: currentDate, configuration: configuration)
        
        return Timeline(entries: [entry], policy: .after(nextMidnight))
    }
}


// MARK: - Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: YearWidgetConfigurationIntent
}

// MARK: - Widget View Principal
struct YearProgressWidgetEntryView: View {
    
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    // Margins
    private let largePaddingWithInfo = EdgeInsets(top: 43, leading: 32, bottom: 12, trailing: 16)
    private let largePaddingWithoutInfo = EdgeInsets(top: 26, leading: 24, bottom: 24, trailing: 24)
    
    private let largeLayoutWithInfo = GridLayoutConfig(columns: 22, spacing: 8, dotSize: 4.9)
    private let largeLayoutNoInfo = GridLayoutConfig(columns: 20, spacing: 8, dotSize: 7)
    
    private var mediumLayoutWithInfo: GridLayoutConfig {
        #if os(iOS)
        return GridLayoutConfig(columns: 27, spacing: 3, dotSize: 5)
        #else
        return GridLayoutConfig(columns: 29, spacing: 3, dotSize: 5)
        #endif
    }
    
    private var mediumLayoutNoInfo: GridLayoutConfig {
        #if os(iOS)
        return GridLayoutConfig(columns: 30, spacing: 4.7, dotSize: 5)
        #else
        return GridLayoutConfig(columns: 30, spacing: 4.7, dotSize: 5)
        #endif
    }
    
    var body: some View {
        ZStack {
            switch family {
            case .systemMedium:
                mediumLayoutView
            case .systemLarge:
                largeLayoutView
            default:
                YearProgressGrid(currentDate: entry.date, layout: mediumLayoutWithInfo)
                    .padding()
            }
        }
        .containerBackground(.thinMaterial, for: .widget)
    }
    
    // MARK: - Sub-views of the Body
    private var mediumLayoutView: some View {
        GeometryReader { geo in
            let showInfo = entry.configuration.showDayInfo
            let totalWidth = geo.size.width
            let infoWidth = showInfo ? totalWidth * 0.33 : totalWidth * 0.0
            let gridWidth = totalWidth - infoWidth
            
            let currentLayout = showInfo ? mediumLayoutWithInfo : mediumLayoutNoInfo
            
            HStack(spacing: 0) {
                YearProgressGrid(currentDate: entry.date, layout: currentLayout)
                    .frame(width: gridWidth)
                    .padding(showInfo ? .init(top: 27, leading: 27, bottom: 25, trailing: 6)
                             : .init(top: 21, leading: 0.5, bottom: 25, trailing: 27))
            
                if showInfo {
                    DayInfoPanel(currentDate: entry.date, style: .medium)
                        .frame(width: infoWidth)
                        .padding(.trailing)
                        .padding(.vertical)
                }
            }
        }
    }
    
    private var largeLayoutView: some View {
        GeometryReader { geo in
            let showInfo = entry.configuration.showDayInfo
            let currentPadding = showInfo ? largePaddingWithInfo : largePaddingWithoutInfo
            let availableWidth = geo.size.width - currentPadding.leading - currentPadding.trailing
            let availableHeight = geo.size.height - currentPadding.top - currentPadding.bottom
            let panelSize = CGSize(width: availableWidth / 3.47, height: availableHeight / 2.5)
            
            ZStack(alignment: .bottomTrailing) {
                if showInfo {
                    YearProgressCutoutGrid(
                        currentDate: entry.date,
                        layout: largeLayoutWithInfo,
                        cutoutSize: panelSize
                    )
                    .padding(currentPadding)
                } else {
                    YearProgressGrid(currentDate: entry.date, layout: largeLayoutNoInfo)
                        .padding(currentPadding)
                }
               
                if showInfo {
                    DayInfoCompactPanel(currentDate: entry.date)
                        .frame(width: panelSize.width, height: panelSize.height, alignment: .bottomTrailing)
                        .background(.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(EdgeInsets(top: 45, leading: 24, bottom: 12, trailing: 0))
                }
            }
        }
    }
    
    // MARK: - Compact Panel
    struct DayInfoCompactPanel: View {
        let currentDate: Date
        
        var body: some View {
            VStack(alignment: .leading, spacing: -4) {
                Text("\(currentDate.dayComponent)")
                    .font(.system(size: 41, weight: .bold))
                
                Text("Passed")
                    .font(.caption).opacity(0.7)
                
                Text("\(currentDate.dayOfYear)")
                    .font(.system(size: 22, weight: .bold))
                    .padding(.top, 4)
                
                Text("Left")
                    .font(.caption).opacity(0.7)
            }
            .padding(EdgeInsets(top: 23, leading: 16, bottom: 16, trailing: 16))
        }
    }
}

// MARK: - Grid with cut
struct YearProgressCutoutGrid: View {
    let currentDate: Date
    let layout: GridLayoutConfig
    let cutoutSize: CGSize

    var body: some View {
        // Uso da Extension
        let daysInYear = currentDate.daysInYear
        let currentDayOfYear = currentDate.dayOfYear
        let rows = makeRows(daysInYear: daysInYear)

        VStack(alignment: .leading, spacing: layout.spacing) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                let row = rows[rowIndex]
                HStack(spacing: layout.spacing) {
                    ForEach(0..<row.count, id: \.self) { col in
                        let dayIndex = row.start + col + 1
                        Circle()
                            .fill(dayIndex <= currentDayOfYear
                                  ? Color.primary.opacity(0.8)
                                  : Color.primary.opacity(0.2))
                            .frame(width: layout.dotSize, height: layout.dotSize)
                    }
                }
            }
        }
    }

    private func makeRows(daysInYear: Int) -> [(start: Int, count: Int)] {
        if cutoutSize == .zero { return makeFullRows(daysInYear: daysInYear) }

        let dotStep = layout.dotSize + layout.spacing
        let marginAdjustment: CGFloat
        let widthAdjustment: CGFloat
        
        #if os(iOS)
        marginAdjustment = 42; widthAdjustment = 22
        #else
        marginAdjustment = 48; widthAdjustment = 21
        #endif
        
        let rowsCut = max(0, Int(ceil((cutoutSize.height - marginAdjustment) / dotStep)))
        let columnsCut = max(0, Int(ceil((cutoutSize.width - widthAdjustment) / dotStep)))
        let shortColumns = max(layout.columns - columnsCut, 1)

        var simulatedDays = 0
        var totalRowsCount = 0
        while simulatedDays < daysInYear {
            totalRowsCount += 1
            simulatedDays += layout.columns
        }
        
        let fullRowsCount = max(totalRowsCount - rowsCut, 0)
        var rows: [(start: Int, count: Int)] = []
        var start = 0
        
        for _ in 0..<fullRowsCount {
            if start >= daysInYear { break }
            let count = min(layout.columns, daysInYear - start)
            rows.append((start: start, count: count))
            start += count
        }
        
        while start < daysInYear {
            let count = min(shortColumns, daysInYear - start)
            rows.append((start: start, count: count))
            start += count
        }
        return rows
    }

    private func makeFullRows(daysInYear: Int) -> [(start: Int, count: Int)] {
        var rows: [(start: Int, count: Int)] = []
        var start = 0
        while start < daysInYear {
            let count = min(layout.columns, daysInYear - start)
            rows.append((start: start, count: count))
            start += count
        }
        return rows
    }
}

// MARK: - Information Panel  (Medium)
struct DayInfoPanel: View {
    enum Style { case medium, large }
    let currentDate: Date
    let style: Style

    var body: some View {
        VStack(alignment: .leading, spacing: style == .medium ? -2 : 10) {
            if style == .medium {
                Text("\(currentDate.dayOfYear)")
                    .font(.system(size: 42, weight: .bold))

                Text("Passed")
                    .font(.caption).opacity(0.7)
                Text("\(currentDate.daysRemaining)")
                    .font(.system(size: 22, weight: .bold))
                Text("Left")
                    .font(.caption).opacity(0.7)
            } else {
                Text("\(currentDate.dayOfYear)")
            }
            Spacer()
        }
        .padding(.leading, style == .medium ? 8 : 10)
        .padding(.top, 8)
    }
}

// MARK: - Progress Grid
struct YearProgressGrid: View {
    let currentDate: Date
    let layout: GridLayoutConfig

    var body: some View {
        let daysInYear = currentDate.daysInYear
        let currentDayOfYear = currentDate.dayOfYear

        LazyVGrid(
            columns: Array(repeating: .init(.fixed(layout.dotSize), spacing: layout.spacing), count: layout.columns),
            spacing: layout.spacing
        ) {
            ForEach(0..<daysInYear, id: \.self) { day in
                Circle()
                    .fill(day < currentDayOfYear ? Color.primary.opacity(0.8) : Color.primary.opacity(0.2))
                    .frame(width: layout.dotSize, height: layout.dotSize)
            }
        }
    }
}

// MARK: - HELPER EXTENSIONS
extension Date {
    var calendar: Calendar { Calendar.current }
    
    var isLeapYear: Bool {
        let year = calendar.component(.year, from: self)
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }
    
    var daysInYear: Int {
        isLeapYear ? 366 : 365
    }
    
    var dayOfYear: Int {
        calendar.ordinality(of: .day, in: .year, for: self) ?? 1
    }
    
    var daysRemaining: Int {
        max(daysInYear - dayOfYear, 0)
    }
    
    var dayComponent: Int {
        calendar.component(.day, from: self)
    }
}

// MARK: - Widget Bundle
struct YearProgressWidget: Widget {
    let kind: String = "Year"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: YearWidgetConfigurationIntent.self, provider: Provider()) { entry in
            YearProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Year")
        .description("YearProgress")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

@main
struct YearWidgetBundle: WidgetBundle {
    var body: some Widget {
        YearProgressWidget()
    }
}
