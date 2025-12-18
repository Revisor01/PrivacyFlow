import SwiftUI
import Charts

// Enum für auswählbare Metriken im Chart
enum ChartMetric: String, CaseIterable {
    case pageviews = "metrics.pageviews"
    case visitors = "metrics.visitors"

    var color: Color {
        switch self {
        case .pageviews: return .blue
        case .visitors: return .purple
        }
    }

    var icon: String {
        switch self {
        case .pageviews: return "eye.fill"
        case .visitors: return "person.fill"
        }
    }
}

enum ChartStyle: String, CaseIterable {
    case line = "chart.style.line"
    case bar = "chart.style.bar"

    var icon: String {
        switch self {
        case .line: return "chart.xyaxis.line"
        case .bar: return "chart.bar.fill"
        }
    }
}

struct WebsiteDetailView: View {
    let website: Website

    @StateObject private var viewModel: WebsiteDetailViewModel
    @State private var selectedDateRange: DateRange = .today
    @State private var selectedChartPoint: TimeSeriesPoint?
    @State private var selectedMetric: ChartMetric = .pageviews
    @State private var selectedChartStyle: ChartStyle = .bar
    @State private var showCustomDatePicker = false
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var customEndDate = Date()

    private var isPlausible: Bool {
        AnalyticsManager.shared.providerType == .plausible
    }

    init(website: Website) {
        self.website = website
        _viewModel = StateObject(wrappedValue: WebsiteDetailViewModel(websiteId: website.id))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                dateRangePicker

                if let stats = viewModel.stats {
                    heroStats(stats)
                }

                if !viewModel.pageviewsData.isEmpty {
                    mainChart
                }

                // Schnellzugriff
                quickActionsSection

                if !viewModel.topPages.isEmpty {
                    topPagesSection
                }

                if !viewModel.referrers.isEmpty {
                    referrersSection
                }

                locationSection

                techSection

                if !viewModel.languages.isEmpty || !viewModel.screens.isEmpty {
                    languageScreenSection
                }

                if !viewModel.events.isEmpty {
                    eventsSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(website.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isPlausible {
                    // Plausible: Just show count, no detail view (no individual user tracking)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("\(viewModel.activeVisitors)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.green.opacity(0.15))
                    .clipShape(Capsule())
                } else {
                    // Umami: Full realtime view with user journeys
                    NavigationLink {
                        RealtimeView(website: website)
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("\(viewModel.activeVisitors)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .contentTransition(.numericText())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.green.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadData(dateRange: selectedDateRange)
        }
        .task {
            await viewModel.loadData(dateRange: selectedDateRange)
        }
        .onChange(of: selectedDateRange) { _, newValue in
            Task {
                await viewModel.loadData(dateRange: newValue)
            }
        }
    }

    // MARK: - Date Range Picker

    private var dateRangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DateRange.allCases, id: \.preset) { range in
                    DateRangeChip(
                        title: range.displayName,
                        isSelected: selectedDateRange.preset == range.preset && selectedDateRange.preset != .custom
                    ) {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedDateRange = range
                        }
                    }
                }

                // Custom Button
                DateRangeChip(
                    title: selectedDateRange.preset == .custom ? selectedDateRange.displayName : String(localized: "daterange.custom"),
                    isSelected: selectedDateRange.preset == .custom
                ) {
                    showCustomDatePicker = true
                }
            }
            .padding(.horizontal, 4)
            .padding(.trailing, 20)
        }
        .mask(
            HStack(spacing: 0) {
                Color.black
                LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 30)
            }
        )
        .sheet(isPresented: $showCustomDatePicker) {
            CustomDateRangePicker(
                startDate: $customStartDate,
                endDate: $customEndDate
            ) {
                withAnimation(.spring(duration: 0.3)) {
                    selectedDateRange = .custom(start: customStartDate, end: customEndDate)
                }
                showCustomDatePicker = false
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Hero Stats

    private func heroStats(_ stats: WebsiteStats) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            // Aufrufe - klickbar, ändert Graph
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    selectedMetric = .pageviews
                    selectedChartPoint = nil
                }
            } label: {
                HeroStatCard(
                    value: stats.pageviews.value.formatted(),
                    label: String(localized: "metrics.pageviews"),
                    change: stats.pageviews.changePercentage,
                    icon: "eye.fill",
                    color: .blue,
                    isSelected: selectedMetric == .pageviews
                )
            }
            .buttonStyle(.plain)

            // Besucher:innen - klickbar für Graph, mit Link zu Sessions (nur Umami)
            if isPlausible {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedMetric = .visitors
                        selectedChartPoint = nil
                    }
                } label: {
                    HeroStatCard(
                        value: stats.visitors.value.formatted(),
                        label: String(localized: "metrics.visitors"),
                        change: stats.visitors.changePercentage,
                        icon: "person.fill",
                        color: .purple,
                        isSelected: selectedMetric == .visitors
                    )
                }
                .buttonStyle(.plain)
            } else {
                HeroStatCardWithLink(
                    value: stats.visitors.value.formatted(),
                    label: String(localized: "metrics.visitors"),
                    change: stats.visitors.changePercentage,
                    icon: "person.fill",
                    color: .purple,
                    isSelected: selectedMetric == .visitors,
                    onTap: {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedMetric = .visitors
                            selectedChartPoint = nil
                        }
                    },
                    destination: { SessionsView(website: website) }
                )
            }

            // Besuche - Navigation zu Retention (nur Umami)
            if isPlausible {
                HeroStatCard(
                    value: stats.visits.value.formatted(),
                    label: String(localized: "metrics.visits"),
                    change: stats.visits.changePercentage,
                    icon: "arrow.triangle.swap",
                    color: .orange
                )
            } else {
                ZStack(alignment: .topTrailing) {
                    NavigationLink {
                        RetentionView(website: website)
                    } label: {
                        HeroStatCard(
                            value: stats.visits.value.formatted(),
                            label: String(localized: "metrics.visits"),
                            change: stats.visits.changePercentage,
                            icon: "arrow.triangle.swap",
                            color: .orange
                        )
                    }
                    .buttonStyle(.plain)

                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.orange, .orange.opacity(0.2))
                        .padding(8)
                }
            }

            HeroStatCard(
                value: String(format: "%.1f%%", stats.bounceRate),
                label: String(localized: "metrics.bounceRate"),
                change: stats.bounces.changePercentage,
                icon: "arrow.uturn.backward",
                color: stats.bounceRate > 50 ? .red : .green,
                invertChangeColor: true
            )

            HeroStatCard(
                value: stats.averageTimeFormatted,
                label: String(localized: "metrics.duration"),
                change: stats.totaltime.changePercentage,
                icon: "clock.fill",
                color: .indigo
            )

            // Live - Navigation zu Realtime (nur Umami)
            if isPlausible {
                HeroStatCard(
                    value: "\(viewModel.activeVisitors)",
                    label: String(localized: "dashboard.live"),
                    change: nil,
                    icon: "wifi",
                    color: .green,
                    isLive: true
                )
            } else {
                NavigationLink {
                    RealtimeView(website: website)
                } label: {
                    HeroStatCard(
                        value: "\(viewModel.activeVisitors)",
                        label: String(localized: "dashboard.live"),
                        change: nil,
                        icon: "wifi",
                        color: .green,
                        isLive: true,
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Main Chart

    // Prüft ob stündliche Daten angezeigt werden (Heute/Gestern)
    private var isHourlyData: Bool {
        selectedDateRange.unit == "hour"
    }

    // Prüft ob Jahresdaten angezeigt werden (Dieses Jahr/Letztes Jahr)
    private var isYearlyData: Bool {
        selectedDateRange.preset == .thisYear || selectedDateRange.preset == .lastYear
    }

    // Prüft ob monatliche Daten angezeigt werden
    private var isMonthlyData: Bool {
        selectedDateRange.unit == "month"
    }

    private var chartXAxisValues: [Date] {
        guard viewModel.pageviewsData.count > 1 else {
            return viewModel.pageviewsData.map { $0.date }
        }

        let dates = viewModel.pageviewsData.map { $0.date }.sorted()
        guard let firstDate = dates.first, let lastDate = dates.last else { return [] }

        // Bei stündlichen Daten (Heute/Gestern): feste Intervalle 0:00, 6:00, 12:00, 18:00
        if isHourlyData {
            var result: [Date] = []
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: firstDate)

            // Feste Intervalle: 0, 6, 12, 18 Uhr
            for hour in [0, 6, 12, 18] {
                if let targetDate = calendar.date(byAdding: .hour, value: hour, to: startOfDay),
                   targetDate <= lastDate {
                    result.append(targetDate)
                }
            }

            // Fallback: wenn keine Intervalle passen, zeige Start und Ende
            if result.isEmpty {
                result = [firstDate, lastDate]
            }

            return result
        }

        let dayCount = Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0

        if dayCount <= 7 {
            // Bei 7 Tagen oder weniger: ersten, letzten und ein paar dazwischen
            if dates.count <= 5 {
                return dates
            }
            // Ersten, 2-3 in der Mitte, letzten
            let step = max(1, dates.count / 4)
            var result: [Date] = [firstDate]
            for i in stride(from: step, to: dates.count - 1, by: step) {
                result.append(dates[i])
            }
            if result.last != lastDate {
                result.append(lastDate)
            }
            return result
        } else if dayCount <= 14 {
            // Bei 8-14 Tagen: 4-5 Werte gleichmäßig verteilt
            let step = max(1, dates.count / 4)
            var result: [Date] = [firstDate]
            for i in stride(from: step, to: dates.count - 1, by: step) {
                result.append(dates[i])
            }
            if result.last != lastDate {
                result.append(lastDate)
            }
            return result
        } else if dayCount <= 31 {
            // Bei 15-31 Tagen: alle 7 Tage + letzter Wert
            var result: [Date] = [firstDate]
            var currentDate = firstDate
            while let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: currentDate),
                  nextWeek < lastDate {
                result.append(nextWeek)
                currentDate = nextWeek
            }
            if result.last != lastDate {
                result.append(lastDate)
            }
            return result
        } else {
            // Bei mehr als 31 Tagen: 4-5 Werte gleichmäßig verteilt
            let step = max(1, dates.count / 4)
            var result: [Date] = [firstDate]
            for i in stride(from: step, to: dates.count - 1, by: step) {
                result.append(dates[i])
            }
            if result.last != lastDate {
                result.append(lastDate)
            }
            return result
        }
    }

    // Aktuelle Chart-Daten basierend auf ausgewählter Metrik
    private var currentChartData: [TimeSeriesPoint] {
        switch selectedMetric {
        case .pageviews:
            return viewModel.pageviewsData
        case .visitors:
            return viewModel.sessionsData
        }
    }

    private var mainChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                chartHeader
                chartContent
            }
        }
    }

    private var chartHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: selectedMetric.icon)
                    .foregroundStyle(selectedMetric.color)
                Text(String(localized: String.LocalizationValue(selectedMetric.rawValue)))
                    .font(.headline)
            }

            Spacer()

            if let point = selectedChartPoint {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(point.value.formatted())
                        .font(.headline)
                        .foregroundStyle(selectedMetric.color)
                    if isHourlyData {
                        Text(point.date, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(point.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            Button {
                withAnimation(.spring(duration: 0.3)) {
                    selectedChartStyle = selectedChartStyle == .line ? .bar : .line
                }
            } label: {
                Image(systemName: selectedChartStyle.icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Circle())
            }
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        let useBarChart = isYearlyData || selectedChartStyle == .bar
        if useBarChart {
            barChartView
        } else {
            lineChartView
        }
    }

    private var lineChartView: some View {
        Chart {
            ForEach(currentChartData) { point in
                LineMark(
                    x: .value("Datum", point.date),
                    y: .value(selectedMetric.rawValue, point.value)
                )
                .foregroundStyle(selectedMetric.color)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }

            ForEach(currentChartData) { point in
                AreaMark(
                    x: .value("Datum", point.date),
                    y: .value(selectedMetric.rawValue, point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [selectedMetric.color.opacity(0.3), selectedMetric.color.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            if currentChartData.count <= 31 {
                ForEach(currentChartData) { point in
                    PointMark(
                        x: .value("Datum", point.date),
                        y: .value(selectedMetric.rawValue, point.value)
                    )
                    .foregroundStyle(selectedMetric.color)
                    .symbolSize(currentChartData.count <= 12 ? 30 : 20)
                }
            }

            if let selected = selectedChartPoint {
                RuleMark(x: .value("Datum", selected.date))
                    .foregroundStyle(.gray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                PointMark(
                    x: .value("Datum", selected.date),
                    y: .value(selectedMetric.rawValue, selected.value)
                )
                .foregroundStyle(selectedMetric.color)
                .symbolSize(80)
                .annotation(position: .top, spacing: 8) {
                    Text("\(selected.value)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(selectedMetric.color)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: chartXAxisValues) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(.gray.opacity(0.3))
                if isHourlyData {
                    AxisValueLabel(format: .dateTime.hour().minute())
                } else {
                    AxisValueLabel(format: .dateTime.day().month())
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateSelectedPoint(at: value.location, geometry: geometry, proxy: proxy)
                            }
                    )
                    .onTapGesture { location in
                        toggleSelectedPoint(at: location, geometry: geometry, proxy: proxy)
                    }
            }
        }
        .frame(height: 220)
    }

    private var barChartView: some View {
        let barUnit: Calendar.Component = isYearlyData ? .month : (isHourlyData ? .hour : .day)

        return Chart {
            ForEach(currentChartData) { point in
                BarMark(
                    x: .value("Datum", point.date, unit: barUnit),
                    y: .value(selectedMetric.rawValue, point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [selectedMetric.color, selectedMetric.color.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
                .annotation(position: .top, spacing: 4) {
                    if selectedChartPoint?.id == point.id {
                        Text("\(point.value)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedMetric.color)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }

            // Gestrichelte Linie bei Auswahl
            if let selected = selectedChartPoint {
                RuleMark(x: .value("Datum", selected.date))
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(.gray.opacity(0.3))
                if isYearlyData {
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                } else if isHourlyData {
                    AxisValueLabel(format: .dateTime.hour())
                } else {
                    AxisValueLabel(format: .dateTime.day().month())
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateSelectedPoint(at: value.location, geometry: geometry, proxy: proxy)
                            }
                            .onEnded { _ in
                                // Punkt bleibt sichtbar bis erneutes Tippen
                            }
                    )
                    .onTapGesture { location in
                        toggleSelectedPoint(at: location, geometry: geometry, proxy: proxy)
                    }
            }
        }
        .frame(height: 220)
    }

    private func updateSelectedPoint(at location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        guard let plotFrame = proxy.plotFrame else { return }
        let x = location.x - geometry[plotFrame].origin.x
        if let date: Date = proxy.value(atX: x) {
            if let closest = currentChartData.min(by: {
                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
            }) {
                withAnimation(.easeOut(duration: 0.1)) {
                    selectedChartPoint = closest
                }
            }
        }
    }

    private func toggleSelectedPoint(at location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        guard let plotFrame = proxy.plotFrame else { return }
        let x = location.x - geometry[plotFrame].origin.x
        if let date: Date = proxy.value(atX: x) {
            withAnimation(.easeOut(duration: 0.15)) {
                if let closest = currentChartData.min(by: {
                    abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                }) {
                    if selectedChartPoint?.id == closest.id {
                        selectedChartPoint = nil
                    } else {
                        selectedChartPoint = closest
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private var quickActionsSection: some View {
        if isPlausible {
            // Plausible: Only Compare is available (no Sessions)
            HStack(spacing: 12) {
                // Vergleich - works for both providers
                NavigationLink {
                    CompareView(website: website)
                } label: {
                    QuickActionCard(
                        icon: "arrow.left.arrow.right",
                        title: String(localized: "compare.title"),
                        subtitle: String(localized: "compare.type"),
                        color: .orange
                    )
                }
                .buttonStyle(.plain)
            }
        } else {
            HStack(spacing: 12) {
                // Sessions / User Journey - Umami only
                NavigationLink {
                    SessionsView(website: website)
                } label: {
                    QuickActionCard(
                        icon: "person.2.fill",
                        title: String(localized: "sessions.tab.sessions"),
                        subtitle: String(localized: "journeys.userJourney"),
                        color: .purple
                    )
                }
                .buttonStyle(.plain)

                // Vergleich
                NavigationLink {
                    CompareView(website: website)
                } label: {
                    QuickActionCard(
                        icon: "arrow.left.arrow.right",
                        title: String(localized: "compare.title"),
                        subtitle: String(localized: "compare.type"),
                        color: .orange
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Top Pages

    @ViewBuilder
    private var topPagesSection: some View {
        if isPlausible {
            // Plausible: No detailed pages view, just show the card without navigation
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: String(localized: "website.topPages"), icon: "doc.text.fill")

                    ForEach(viewModel.topPages.prefix(8), id: \.name) { page in
                        HStack(alignment: .top) {
                            Text(page.name)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Text(page.value.formatted())
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 4)

                        if page.name != viewModel.topPages.prefix(8).last?.name {
                            Divider()
                        }
                    }
                }
            }
        } else {
            NavigationLink {
                PagesView(website: website)
            } label: {
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            SectionHeader(title: String(localized: "website.topPages"), icon: "doc.text.fill")
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                    // Kombiniere Titel und Pfade für die Anzeige
                    let combinedItems = createCombinedItems()

                    ForEach(combinedItems.prefix(8), id: \.path) { item in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline)
                                    .lineLimit(1)

                                Text(website.displayDomain + item.path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(item.views.formatted())
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 4)

                        if item.path != combinedItems.prefix(8).last?.path {
                            Divider()
                        }
                    }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private struct CombinedItem {
        let title: String
        let path: String
        let views: Int
    }

    private func createCombinedItems() -> [CombinedItem] {
        var result: [CombinedItem] = []
        var usedTitles: Set<String> = []

        for page in viewModel.topPages {
            // Suche passenden Titel basierend auf Aufrufzahlen
            let matchingTitle = viewModel.pageTitles.first { title in
                !usedTitles.contains(title.name) &&
                abs(title.value - page.value) <= max(1, Int(Double(page.value) * 0.15))
            }

            let title: String
            if let match = matchingTitle {
                usedTitles.insert(match.name)
                title = match.name
            } else {
                title = extractTitleFromPath(page.name)
            }

            result.append(CombinedItem(title: title, path: page.name, views: page.value))
        }

        return result
    }

    private func extractTitleFromPath(_ path: String) -> String {
        if path == "/" { return String(localized: "website.homepage") }
        let mainPath = path.split(separator: "?").first ?? Substring(path)
        let segments = mainPath.trimmingCharacters(in: CharacterSet(charactersIn: "/")).split(separator: "/")
        if let lastSegment = segments.last {
            return String(lastSegment).replacingOccurrences(of: "-", with: " ").capitalized
        }
        return path
    }

    // MARK: - Referrers

    private var referrersSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: String(localized: "website.referrers"), icon: "link")

                ForEach(viewModel.referrers.prefix(8)) { item in
                    HStack {
                        Text(item.name.isEmpty ? String(localized: "website.referrer.direct") : shortenReferrer(item.name))
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        Text(item.value.formatted())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)

                    if item.id != viewModel.referrers.prefix(8).last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Location Section

    private var locationSection: some View {
        VStack(spacing: 16) {
            if !viewModel.countries.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: String(localized: "website.countries"), icon: "globe.europe.africa.fill")

                        ForEach(viewModel.countries.prefix(8)) { country in
                            HStack {
                                Text(countryFlag(country.name))
                                    .font(.title3)
                                Text(countryName(country.name))
                                    .font(.subheadline)
                                Spacer()

                                let total = viewModel.countries.reduce(0) { $0 + $1.value }
                                let percentage = total > 0 ? Double(country.value) / Double(total) * 100 : 0

                                Text(String(format: "%.1f%%", percentage))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .trailing)

                                Text(country.value.formatted())
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(width: 60, alignment: .trailing)
                            }

                            if country.id != viewModel.countries.prefix(8).last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }

            HStack(alignment: .top, spacing: 16) {
                if !viewModel.regions.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: String(localized: "website.regions"), icon: "map.fill")

                            ForEach(viewModel.regions.prefix(5)) { region in
                                HStack {
                                    Text(region.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(region.value.formatted())
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                }

                if !viewModel.cities.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: String(localized: "website.cities"), icon: "building.2.fill")

                            ForEach(viewModel.cities.prefix(5)) { city in
                                HStack {
                                    Text(city.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(city.value.formatted())
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tech Section

    private var techSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                if !viewModel.devices.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: String(localized: "website.devices"), icon: "iphone")

                            Chart(viewModel.devices, id: \.id) { item in
                                SectorMark(
                                    angle: .value("Anzahl", item.value),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 2
                                )
                                .foregroundStyle(deviceColor(item.name))
                                .cornerRadius(4)
                            }
                            .frame(height: 120)

                            ForEach(viewModel.devices) { item in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(deviceColor(item.name))
                                        .frame(width: 8, height: 8)
                                    Text(deviceName(item.name))
                                        .font(.caption)
                                    Spacer()
                                    Text(item.value.formatted())
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                }

                if !viewModel.browsers.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: String(localized: "website.browsers"), icon: "globe")

                            Chart(viewModel.browsers.prefix(5), id: \.id) { item in
                                SectorMark(
                                    angle: .value("Anzahl", item.value),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 2
                                )
                                .foregroundStyle(browserColor(item.name))
                                .cornerRadius(4)
                            }
                            .frame(height: 120)

                            ForEach(viewModel.browsers.prefix(5)) { item in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(browserColor(item.name))
                                        .frame(width: 8, height: 8)
                                    Text(item.name.capitalized)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(item.value.formatted())
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                }
            }

            if !viewModel.operatingSystems.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: String(localized: "website.os"), icon: "desktopcomputer")

                        ForEach(viewModel.operatingSystems.prefix(6)) { item in
                            HStack {
                                Image(systemName: osIcon(item.name))
                                    .frame(width: 20)
                                    .foregroundStyle(.secondary)
                                Text(item.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(item.value.formatted())
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Language & Screen Section

    private var languageScreenSection: some View {
        HStack(alignment: .top, spacing: 16) {
            if !viewModel.languages.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: String(localized: "website.languages"), icon: "character.bubble.fill")

                        ForEach(viewModel.languages.prefix(5)) { language in
                            HStack {
                                Text(languageFlag(language.name))
                                Text(languageName(language.name))
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text(language.value.formatted())
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }

            if !viewModel.screens.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: String(localized: "website.screens"), icon: "rectangle.dashed")

                        ForEach(viewModel.screens.prefix(5)) { screen in
                            HStack {
                                Image(systemName: screenIcon(screen.name))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(screen.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text(screen.value.formatted())
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Events Section

    private var eventsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Events", icon: "bell.fill")

                ForEach(viewModel.events.prefix(8)) { item in
                    HStack {
                        Text(item.name)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        Text(item.value.formatted())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)

                    if item.id != viewModel.events.prefix(8).last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func shortenReferrer(_ referrer: String) -> String {
        var result = referrer
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")

        if let slashIndex = result.firstIndex(of: "/") {
            result = String(result[..<slashIndex])
        }

        return result.count > 25 ? String(result.prefix(22)) + "..." : result
    }

    private func countryFlag(_ code: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in code.uppercased().unicodeScalars {
            if let unicode = UnicodeScalar(base + scalar.value) {
                flag.append(String(unicode))
            }
        }
        return flag.isEmpty ? "🌍" : flag
    }

    private func countryName(_ code: String) -> String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }

    private func deviceName(_ name: String) -> String {
        switch name.lowercased() {
        case "desktop": return String(localized: "device.desktop")
        case "mobile": return String(localized: "device.mobile")
        case "tablet": return String(localized: "device.tablet")
        default: return name
        }
    }

    private func osIcon(_ name: String) -> String {
        let lowercased = name.lowercased()
        if lowercased.contains("windows") { return "pc" }
        if lowercased.contains("mac") || lowercased.contains("os x") { return "desktopcomputer" }
        if lowercased.contains("ios") || lowercased.contains("iphone") { return "iphone" }
        if lowercased.contains("android") { return "candybarphone" }
        if lowercased.contains("linux") { return "terminal" }
        if lowercased.contains("chrome") { return "globe" }
        return "desktopcomputer"
    }

    private func languageFlag(_ code: String) -> String {
        let languageToCountry: [String: String] = [
            "de": "DE", "en": "GB", "fr": "FR", "es": "ES", "it": "IT",
            "pt": "PT", "nl": "NL", "pl": "PL", "ru": "RU", "ja": "JP",
            "zh": "CN", "ko": "KR", "ar": "SA", "tr": "TR", "sv": "SE"
        ]

        let langCode = String(code.prefix(2)).lowercased()
        if let countryCode = languageToCountry[langCode] {
            return countryFlag(countryCode)
        }
        return "🌐"
    }

    private func languageName(_ code: String) -> String {
        let locale = Locale.current
        let langCode = String(code.prefix(2))
        return locale.localizedString(forLanguageCode: langCode) ?? code
    }

    private func screenIcon(_ size: String) -> String {
        let parts = size.split(separator: "x")
        if let width = parts.first, let w = Int(width) {
            if w < 768 { return "iphone" }
            if w < 1024 { return "ipad" }
            return "desktopcomputer"
        }
        return "rectangle"
    }

    private func deviceColor(_ name: String) -> Color {
        switch name.lowercased() {
        case "desktop", "laptop": return .blue
        case "mobile": return .green
        case "tablet": return .orange
        default: return .purple
        }
    }

    private func browserColor(_ name: String) -> Color {
        let lowercased = name.lowercased()
        if lowercased.contains("chrome") { return .yellow }
        if lowercased.contains("safari") || lowercased.contains("ios") { return .blue }
        if lowercased.contains("firefox") { return .orange }
        if lowercased.contains("edge") { return .cyan }
        if lowercased.contains("samsung") { return .purple }
        if lowercased.contains("opera") { return .red }
        return .gray
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Image(systemName: icon)
                .foregroundStyle(.secondary)
        }
    }
}

struct DateRangeChip: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
            }
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.primary : .clear)
            .foregroundColor(isSelected ? Color(.systemBackground) : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? .clear : .secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct HeroStatCard: View {
    let value: String
    let label: String
    let change: Double?
    let icon: String
    let color: Color
    var isLive: Bool = false
    var invertChangeColor: Bool = false
    var showChevron: Bool = false
    var isSelected: Bool = false

    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)

                Spacer()

                if isLive {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(.green.opacity(0.5), lineWidth: 2)
                                .scaleEffect(isAnimating ? 2 : 1)
                                .opacity(isAnimating ? 0 : 1)
                        )
                        .onAppear {
                            withAnimation(.easeOut(duration: 1).repeatForever(autoreverses: false)) {
                                isAnimating = true
                            }
                        }
                } else if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .contentTransition(.numericText())

            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let change = change, change != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                        Text(String(format: "%.0f%%", abs(change)))
                    }
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(changeColor(change))
                }
            }
        }
        .padding()
        .background(isSelected ? color.opacity(0.15) : Color(.secondarySystemGroupedBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? color : .clear, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func changeColor(_ change: Double) -> Color {
        if invertChangeColor {
            return change > 0 ? .red : .green
        }
        return change > 0 ? .green : .red
    }
}

struct HeroStatCardWithLink<Destination: View>: View {
    let value: String
    let label: String
    let change: Double?
    let icon: String
    let color: Color
    var isSelected: Bool = false
    let onTap: () -> Void
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: icon)
                            .foregroundStyle(color)
                        Spacer()
                    }

                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .contentTransition(.numericText())

                    HStack(spacing: 4) {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let change = change, change != 0 {
                            HStack(spacing: 2) {
                                Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                                Text(String(format: "%.0f%%", abs(change)))
                            }
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(change > 0 ? .green : .red)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isSelected ? color.opacity(0.15) : Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? color : .clear, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            // Link-Button oben rechts
            NavigationLink(destination: destination) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(color, color.opacity(0.2))
            }
            .padding(8)
        }
    }
}

struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    var isDashed: Bool = false
    var isPoint: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if isPoint {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            } else if isDashed {
                Rectangle()
                    .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
                    .frame(width: 16, height: 2)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 2)
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct CustomDateRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        String(localized: "button.back"),
                        selection: $startDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )

                    DatePicker(
                        String(localized: "button.next"),
                        selection: $endDate,
                        in: startDate...Date(),
                        displayedComponents: .date
                    )
                }

                Section {
                    Button {
                        onApply()
                    } label: {
                        HStack {
                            Spacer()
                            Text(String(localized: "button.done"))
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "daterange.custom"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WebsiteDetailView(
            website: Website(
                id: "1",
                name: "Test Website",
                domain: "test.de",
                shareId: nil,
            teamId: nil,
                resetAt: nil,
                createdAt: nil
            )
        )
    }
}
