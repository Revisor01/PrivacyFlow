import SwiftUI
import Charts

enum CompareType: String, CaseIterable {
    case week = "compare.week"
    case month = "compare.month"
    case year = "compare.year"
}

enum CompareMetric: String, CaseIterable {
    case pageviews = "metrics.pageviews"
    case visitors = "metrics.visitors"

    var icon: String {
        switch self {
        case .pageviews: return "eye.fill"
        case .visitors: return "person.fill"
        }
    }

    var color: Color {
        switch self {
        case .pageviews: return .blue
        case .visitors: return .purple
        }
    }
}

struct CompareView: View {
    let website: Website

    @StateObject private var viewModel: CompareViewModel
    @State private var compareType: CompareType = .week
    @State private var chartStyle: ChartStyle = .bar
    @State private var selectedPointIndex: Int?
    @State private var selectedPeriod: String?
    @State private var selectedMetric: CompareMetric = .pageviews

    // Periode A
    @State private var periodAWeek: Int = Calendar.current.component(.weekOfYear, from: Date())
    @State private var periodAMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var periodAYear: Int = Calendar.current.component(.year, from: Date())

    // Periode B (Standard: gleiche Woche/Monat, letztes Jahr)
    @State private var periodBWeek: Int = Calendar.current.component(.weekOfYear, from: Date())
    @State private var periodBMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var periodBYear: Int = Calendar.current.component(.year, from: Date()) - 1

    init(website: Website) {
        self.website = website
        _viewModel = StateObject(wrappedValue: CompareViewModel(websiteId: website.id))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Perioden-Auswahl
                periodSelectionSection

                // Vergleichen Button
                compareButton

                // Ergebnisse
                if let stats1 = viewModel.stats1, let stats2 = viewModel.stats2 {
                    comparisonStatsSection(stats1: stats1, stats2: stats2)
                    comparisonChartSection
                } else if viewModel.isLoading {
                    ProgressView(String(localized: "compare.loading"))
                        .padding(40)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(String(localized: "compare.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker(String(localized: "compare.type"), selection: $compareType) {
                    ForEach(CompareType.allCases, id: \.self) { type in
                        Text(String(localized: String.LocalizationValue(type.rawValue))).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
        }
    }

    // MARK: - Period Selection

    private var periodSelectionSection: some View {
        VStack(spacing: 16) {
            // Periode A
            periodCard(
                title: String(localized: "compare.periodA"),
                color: .blue,
                week: $periodAWeek,
                month: $periodAMonth,
                year: $periodAYear
            )

            // VS Divider
            HStack {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                Text(String(localized: "compare.vs"))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
            }

            // Periode B
            periodCard(
                title: String(localized: "compare.periodB"),
                color: .orange,
                week: $periodBWeek,
                month: $periodBMonth,
                year: $periodBYear
            )
        }
    }

    private func periodCard(title: String, color: Color, week: Binding<Int>, month: Binding<Int>, year: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(periodLabel(week: week.wrappedValue, month: month.wrappedValue, year: year.wrappedValue))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                switch compareType {
                case .week:
                    // Woche
                    Picker(String(localized: "compare.calendarWeek"), selection: week) {
                        ForEach(1...53, id: \.self) { w in
                            Text(String(localized: "compare.calendarWeek") + " \(w)").tag(w)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                case .month:
                    // Monat
                    Picker(String(localized: "compare.month"), selection: month) {
                        ForEach(1...12, id: \.self) { m in
                            Text(monthName(m)).tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                case .year:
                    EmptyView()
                }

                // Jahr (immer sichtbar)
                Picker(String(localized: "compare.year"), selection: year) {
                    ForEach((2020...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { y in
                        Text(String(y)).tag(y)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: compareType == .year ? .infinity : nil)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func periodLabel(week: Int, month: Int, year: Int) -> String {
        switch compareType {
        case .week:
            return String(localized: "compare.calendarWeek") + " \(week), \(year)"
        case .month:
            return "\(monthName(month)) \(year)"
        case .year:
            return "\(year)"
        }
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.monthSymbols[month - 1]
    }

    // MARK: - Compare Button

    private var compareButton: some View {
        Button {
            Task {
                await loadComparison()
            }
        } label: {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                Text(String(localized: "compare.button"))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.isLoading)
    }

    private func loadComparison() async {
        let dateRange1 = createDateRange(week: periodAWeek, month: periodAMonth, year: periodAYear)
        let dateRange2 = createDateRange(week: periodBWeek, month: periodBMonth, year: periodBYear)
        await viewModel.loadComparison(dateRange1: dateRange1, dateRange2: dateRange2)
    }

    private func createDateRange(week: Int, month: Int, year: Int) -> DateRange {
        let calendar = Calendar.current

        switch compareType {
        case .week:
            // Kalenderwoche zu Datum
            var components = DateComponents()
            components.weekOfYear = week
            components.yearForWeekOfYear = year
            components.weekday = 2 // Montag

            guard let startOfWeek = calendar.date(from: components) else {
                return .last7Days
            }
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
            return .custom(start: startOfWeek, end: min(endOfWeek, Date()))

        case .month:
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = month
            startComponents.day = 1

            guard let startOfMonth = calendar.date(from: startComponents) else {
                return .thisMonth
            }

            var endComponents = DateComponents()
            endComponents.month = 1
            endComponents.day = -1
            let endOfMonth = calendar.date(byAdding: endComponents, to: startOfMonth)!

            return .custom(start: startOfMonth, end: min(endOfMonth, Date()))

        case .year:
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = 1
            startComponents.day = 1

            var endComponents = DateComponents()
            endComponents.year = year
            endComponents.month = 12
            endComponents.day = 31

            guard let start = calendar.date(from: startComponents),
                  let end = calendar.date(from: endComponents) else {
                return .thisYear
            }

            return .custom(start: start, end: min(end, Date()))
        }
    }

    // MARK: - Comparison Stats

    private func comparisonStatsSection(stats1: WebsiteStats, stats2: WebsiteStats) -> some View {
        VStack(spacing: 16) {
            // Header mit Perioden
            HStack {
                VStack(alignment: .leading) {
                    Circle().fill(.blue).frame(width: 8, height: 8)
                    Text(periodLabel(week: periodAWeek, month: periodAMonth, year: periodAYear))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Circle().fill(.orange).frame(width: 8, height: 8)
                    Text(periodLabel(week: periodBWeek, month: periodBMonth, year: periodBYear))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 8)

            // Anklickbare Hero Cards - alle 4 Werte
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Aufrufe Hero - klickbar
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedMetric = .pageviews
                        selectedPointIndex = nil
                    }
                } label: {
                    CompareHeroCard(
                        label: String(localized: "metrics.pageviews"),
                        icon: "eye.fill",
                        value1: stats1.pageviews.value,
                        value2: stats2.pageviews.value,
                        isSelected: selectedMetric == .pageviews
                    )
                }
                .buttonStyle(.plain)

                // Besucher Hero - klickbar
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedMetric = .visitors
                        selectedPointIndex = nil
                    }
                } label: {
                    CompareHeroCard(
                        label: String(localized: "metrics.visitors"),
                        icon: "person.fill",
                        value1: stats1.visitors.value,
                        value2: stats2.visitors.value,
                        isSelected: selectedMetric == .visitors
                    )
                }
                .buttonStyle(.plain)

                // Besuche Hero (nicht anklickbar für Graph)
                CompareHeroCard(
                    label: String(localized: "metrics.visits"),
                    icon: "arrow.triangle.swap",
                    value1: stats1.visits.value,
                    value2: stats2.visits.value,
                    isSelected: false
                )

                // Absprungrate Hero
                CompareHeroCard(
                    label: String(localized: "metrics.bounceRate"),
                    icon: "arrow.uturn.backward",
                    value1: Int(stats1.bounceRate),
                    value2: Int(stats2.bounceRate),
                    isSelected: false,
                    isPercentage: true,
                    invertBetter: true
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Comparison Chart

    private var comparisonChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            comparisonChartHeader
            comparisonChartLegend
            comparisonChartContent
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // Erwartete Anzahl Datenpunkte basierend auf Vergleichstyp
    private var expectedDataPoints: Int {
        switch compareType {
        case .week: return 7
        case .month: return 31
        case .year: return 12
        }
    }

    // Aktuelle Chart-Daten basierend auf ausgewählter Metrik - mit Padding
    private var currentData1: [TimeSeriesPoint] {
        let rawData: [TimeSeriesPoint]
        switch selectedMetric {
        case .pageviews: rawData = viewModel.pageviews1
        case .visitors: rawData = viewModel.visitors1
        }
        return padDataToExpectedCount(rawData)
    }

    private var currentData2: [TimeSeriesPoint] {
        let rawData: [TimeSeriesPoint]
        switch selectedMetric {
        case .pageviews: rawData = viewModel.pageviews2
        case .visitors: rawData = viewModel.visitors2
        }
        return padDataToExpectedCountB(rawData)
    }

    // Erstellt ein vollständiges Array mit Daten an den korrekten Positionen
    private func padDataToExpectedCount(_ data: [TimeSeriesPoint]) -> [TimeSeriesPoint] {
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Erstelle leeres Array mit Platzhaltern
        var result: [TimeSeriesPoint] = []

        switch compareType {
        case .week:
            // 7 Tage: Mo-So (Index 0-6)
            // Erstelle Basis-Datum für die Woche
            var components = DateComponents()
            components.weekOfYear = periodAWeek
            components.yearForWeekOfYear = periodAYear
            components.weekday = 2 // Montag
            let weekStart = calendar.date(from: components) ?? Date()

            for dayIndex in 0..<7 {
                let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart)!
                // Suche passenden Datenpunkt
                let matchingPoint = data.first { point in
                    let pointDay = calendar.component(.weekday, from: point.date)
                    // Konvertiere Sonntag (1) zu 7, Rest -1
                    let normalizedDay = pointDay == 1 ? 6 : pointDay - 2
                    return normalizedDay == dayIndex
                }
                let dateString = formatter.string(from: targetDate)
                result.append(TimeSeriesPoint(x: dateString, y: matchingPoint?.value ?? 0))
            }

        case .month:
            // 31 Tage: 1.-31. (Index 0-30)
            var startComponents = DateComponents()
            startComponents.year = periodAYear
            startComponents.month = periodAMonth
            startComponents.day = 1
            let monthStart = calendar.date(from: startComponents) ?? Date()

            // Anzahl Tage im Monat
            let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 31

            for dayIndex in 0..<daysInMonth {
                let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: monthStart)!
                let targetDay = dayIndex + 1
                // Suche passenden Datenpunkt
                let matchingPoint = data.first { point in
                    calendar.component(.day, from: point.date) == targetDay
                }
                let dateString = formatter.string(from: targetDate)
                result.append(TimeSeriesPoint(x: dateString, y: matchingPoint?.value ?? 0))
            }

        case .year:
            // 12 Monate: Jan-Dez (Index 0-11)
            for monthIndex in 0..<12 {
                var targetComponents = DateComponents()
                targetComponents.year = periodAYear
                targetComponents.month = monthIndex + 1
                targetComponents.day = 1
                let targetDate = calendar.date(from: targetComponents) ?? Date()

                // Suche passenden Datenpunkt für diesen Monat
                let matchingPoint = data.first { point in
                    calendar.component(.month, from: point.date) == monthIndex + 1
                }
                let dateString = formatter.string(from: targetDate)
                result.append(TimeSeriesPoint(x: dateString, y: matchingPoint?.value ?? 0))
            }
        }

        return result
    }

    // Separate Funktion für Periode B
    private func padDataToExpectedCountB(_ data: [TimeSeriesPoint]) -> [TimeSeriesPoint] {
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var result: [TimeSeriesPoint] = []

        switch compareType {
        case .week:
            var components = DateComponents()
            components.weekOfYear = periodBWeek
            components.yearForWeekOfYear = periodBYear
            components.weekday = 2
            let weekStart = calendar.date(from: components) ?? Date()

            for dayIndex in 0..<7 {
                let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart)!
                let matchingPoint = data.first { point in
                    let pointDay = calendar.component(.weekday, from: point.date)
                    let normalizedDay = pointDay == 1 ? 6 : pointDay - 2
                    return normalizedDay == dayIndex
                }
                let dateString = formatter.string(from: targetDate)
                result.append(TimeSeriesPoint(x: dateString, y: matchingPoint?.value ?? 0))
            }

        case .month:
            var startComponents = DateComponents()
            startComponents.year = periodBYear
            startComponents.month = periodBMonth
            startComponents.day = 1
            let monthStart = calendar.date(from: startComponents) ?? Date()
            let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 31

            for dayIndex in 0..<daysInMonth {
                let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: monthStart)!
                let targetDay = dayIndex + 1
                let matchingPoint = data.first { point in
                    calendar.component(.day, from: point.date) == targetDay
                }
                let dateString = formatter.string(from: targetDate)
                result.append(TimeSeriesPoint(x: dateString, y: matchingPoint?.value ?? 0))
            }

        case .year:
            for monthIndex in 0..<12 {
                var targetComponents = DateComponents()
                targetComponents.year = periodBYear
                targetComponents.month = monthIndex + 1
                targetComponents.day = 1
                let targetDate = calendar.date(from: targetComponents) ?? Date()

                let matchingPoint = data.first { point in
                    calendar.component(.month, from: point.date) == monthIndex + 1
                }
                let dateString = formatter.string(from: targetDate)
                result.append(TimeSeriesPoint(x: dateString, y: matchingPoint?.value ?? 0))
            }
        }

        return result
    }

    // Farbe für Periode A basierend auf Metrik
    private var periodAColor: Color {
        selectedMetric == .pageviews ? .blue : .purple
    }

    private var comparisonChartHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: selectedMetric.icon)
                    .foregroundStyle(periodAColor)
                Text(String(localized: String.LocalizationValue(selectedMetric.rawValue)) + " " + String(localized: "compare.inComparison"))
                    .font(.headline)
            }

            Spacer()

            // Ausgewählter Punkt
            if let index = selectedPointIndex {
                let value1 = index < currentData1.count ? currentData1[index].value : 0
                let value2 = index < currentData2.count ? currentData2[index].value : 0

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("\(value1)").foregroundStyle(periodAColor)
                        Text("/")
                        Text("\(value2)").foregroundStyle(.orange)
                    }
                    .font(.headline)
                    Text(xAxisLabel(for: index))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                withAnimation(.spring(duration: 0.3)) {
                    chartStyle = chartStyle == .line ? .bar : .line
                }
            } label: {
                Image(systemName: chartStyle.icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Circle())
            }
        }
    }

    private var comparisonChartLegend: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(periodAColor)
                    .frame(width: 16, height: 3)
                Text(periodLabel(week: periodAWeek, month: periodAMonth, year: periodAYear))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.orange)
                    .frame(width: 16, height: 3)
                Text(periodLabel(week: periodBWeek, month: periodBMonth, year: periodBYear))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var comparisonChartContent: some View {
        if !currentData1.isEmpty || !currentData2.isEmpty {
            let useBarChart = compareType == .year || chartStyle == .bar
            if useBarChart {
                comparisonBarChart
            } else {
                comparisonLineChart
            }
        }
    }

    private func xAxisLabel(for index: Int) -> String {
        let calendar = Calendar.current

        switch compareType {
        case .week:
            // Zeige Datum (z.B. "9.12.")
            var components = DateComponents()
            components.weekOfYear = periodAWeek
            components.yearForWeekOfYear = periodAYear
            components.weekday = 2 // Montag
            if let weekStart = calendar.date(from: components),
               let date = calendar.date(byAdding: .day, value: index, to: weekStart) {
                let day = calendar.component(.day, from: date)
                let month = calendar.component(.month, from: date)
                return "\(day).\(month)."
            }
            return "\(index + 1)"
        case .month:
            return "\(index + 1)."
        case .year:
            let months = [
                String(localized: "compare.months.jan"),
                String(localized: "compare.months.feb"),
                String(localized: "compare.months.mar"),
                String(localized: "compare.months.apr"),
                String(localized: "compare.months.may"),
                String(localized: "compare.months.jun"),
                String(localized: "compare.months.jul"),
                String(localized: "compare.months.aug"),
                String(localized: "compare.months.sep"),
                String(localized: "compare.months.oct"),
                String(localized: "compare.months.nov"),
                String(localized: "compare.months.dec")
            ]
            return index < months.count ? months[index] : "\(index + 1)"
        }
    }

    // X-Achsen Werte für Chart (gefiltert für Monat)
    private func shouldShowXAxisLabel(for index: Int, totalCount: Int) -> Bool {
        switch compareType {
        case .week:
            return true // Alle 7 Tage zeigen
        case .month:
            // Nur 1., 15. und letzter Tag
            let day = index + 1
            return day == 1 || day == 15 || day == totalCount
        case .year:
            return true // Alle 12 Monate zeigen
        }
    }

    private var comparisonLineChart: some View {
        let maxCount = max(currentData1.count, currentData2.count)
        let chartColor = periodAColor

        return Chart {
            ForEach(Array(currentData1.enumerated()), id: \.offset) { index, point in
                LineMark(
                    x: .value("X", index),
                    y: .value(selectedMetric.rawValue, point.value),
                    series: .value("Periode", "A")
                )
                .foregroundStyle(chartColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }

            ForEach(Array(currentData1.enumerated()), id: \.offset) { index, point in
                AreaMark(
                    x: .value("X", index),
                    y: .value(selectedMetric.rawValue, point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [chartColor.opacity(0.2), chartColor.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            ForEach(Array(currentData2.enumerated()), id: \.offset) { index, point in
                LineMark(
                    x: .value("X", index),
                    y: .value(selectedMetric.rawValue, point.value),
                    series: .value("Periode", "B")
                )
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .interpolationMethod(.catmullRom)
            }

            // Datenpunkte
            ForEach(Array(currentData1.enumerated()), id: \.offset) { index, point in
                PointMark(
                    x: .value("X", index),
                    y: .value(selectedMetric.rawValue, point.value)
                )
                .foregroundStyle(chartColor)
                .symbolSize(selectedPointIndex == index ? 60 : (maxCount <= 12 ? 30 : 20))
            }

            ForEach(Array(currentData2.enumerated()), id: \.offset) { index, point in
                PointMark(
                    x: .value("X", index),
                    y: .value(selectedMetric.rawValue, point.value)
                )
                .foregroundStyle(.orange)
                .symbolSize(selectedPointIndex == index ? 60 : (maxCount <= 12 ? 30 : 20))
            }

            // Selection indicator
            if let idx = selectedPointIndex {
                RuleMark(x: .value("X", idx))
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 1)) { value in
                if let index = value.as(Int.self), shouldShowXAxisLabel(for: index, totalCount: maxCount) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel {
                        Text(xAxisLabel(for: index))
                            .font(.caption2)
                    }
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
                                updateCompareSelectedPoint(at: value.location, geometry: geometry, proxy: proxy)
                            }
                    )
                    .onTapGesture { location in
                        handleCompareChartTap(location: location, geometry: geometry, proxy: proxy)
                    }
            }
        }
        .chartLegend(.hidden)
        .frame(height: 220)
    }

    private func updateCompareSelectedPoint(at location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        let x = location.x - geometry[proxy.plotFrame!].origin.x
        if let index: Int = proxy.value(atX: x) {
            let maxCount = max(currentData1.count, currentData2.count)
            let clampedIndex = max(0, min(index, maxCount - 1))
            withAnimation(.easeOut(duration: 0.1)) {
                selectedPointIndex = clampedIndex
            }
        }
    }

    private var comparisonBarChart: some View {
        let chartColor = periodAColor
        let maxCount = max(currentData1.count, currentData2.count)

        return Chart {
            ForEach(Array(currentData1.enumerated()), id: \.offset) { index, point in
                BarMark(
                    x: .value("X", xAxisLabel(for: index)),
                    y: .value(selectedMetric.rawValue, point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [chartColor, chartColor.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(3)
                .position(by: .value("Periode", "A"))
                .annotation(position: .top) {
                    if selectedPointIndex == index && selectedPeriod == "A" {
                        Text("\(point.value)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(chartColor)
                    }
                }
            }

            ForEach(Array(currentData2.enumerated()), id: \.offset) { index, point in
                BarMark(
                    x: .value("X", xAxisLabel(for: index)),
                    y: .value(selectedMetric.rawValue, point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(3)
                .position(by: .value("Periode", "B"))
                .annotation(position: .top) {
                    if selectedPointIndex == index && selectedPeriod == "B" {
                        Text("\(point.value)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                if let label = value.as(String.self) {
                    // Für Monat: nur 1., 15. und letzter Tag
                    let shouldShow = compareType != .month ||
                        label == "1." || label == "15." || label == "\(maxCount)."
                    if shouldShow {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(.gray.opacity(0.3))
                        AxisValueLabel {
                            Text(label)
                                .font(.caption2)
                        }
                    }
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
                                updateCompareBarSelectedPoint(at: value.location, geometry: geometry, proxy: proxy)
                            }
                    )
                    .onTapGesture { location in
                        handleCompareBarTap(location: location, geometry: geometry, proxy: proxy)
                    }
            }
        }
        .chartLegend(.hidden)
        .frame(height: 220)
    }

    private func updateCompareBarSelectedPoint(at location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        let x = location.x - geometry[proxy.plotFrame!].origin.x
        let plotWidth = geometry[proxy.plotFrame!].width
        let maxCount = max(currentData1.count, currentData2.count)

        // Berechne Index basierend auf Position
        let index = Int((x / plotWidth) * CGFloat(maxCount))
        let clampedIndex = max(0, min(index, maxCount - 1))

        // Bestimme ob linke (A) oder rechte (B) Bar
        let barWidth = plotWidth / CGFloat(maxCount)
        let posInBar = x.truncatingRemainder(dividingBy: barWidth)
        let period = posInBar < barWidth / 2 ? "A" : "B"

        withAnimation(.easeOut(duration: 0.1)) {
            selectedPointIndex = clampedIndex
            selectedPeriod = period
        }
    }

    private func handleCompareChartTap(location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        let x = location.x - geometry[proxy.plotFrame!].origin.x
        if let index: Int = proxy.value(atX: x) {
            withAnimation(.easeOut(duration: 0.15)) {
                if selectedPointIndex == index {
                    selectedPointIndex = nil
                } else {
                    selectedPointIndex = index
                }
            }
        }
    }

    private func handleCompareBarTap(location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        let x = location.x - geometry[proxy.plotFrame!].origin.x
        let plotWidth = geometry[proxy.plotFrame!].width
        let maxCount = max(currentData1.count, currentData2.count)

        // Berechne Index basierend auf Position
        let index = Int((x / plotWidth) * CGFloat(maxCount))
        let clampedIndex = max(0, min(index, maxCount - 1))

        // Bestimme ob linke (A) oder rechte (B) Bar
        let barWidth = plotWidth / CGFloat(maxCount)
        let posInBar = x.truncatingRemainder(dividingBy: barWidth)
        let period = posInBar < barWidth / 2 ? "A" : "B"

        withAnimation(.easeOut(duration: 0.15)) {
            if selectedPointIndex == clampedIndex && selectedPeriod == period {
                selectedPointIndex = nil
                selectedPeriod = nil
            } else {
                selectedPointIndex = clampedIndex
                selectedPeriod = period
            }
        }
    }
}

// MARK: - Compare Hero Card

struct CompareHeroCard: View {
    let label: String
    let icon: String
    let value1: Int
    let value2: Int
    var isSelected: Bool = false
    var isPercentage: Bool = false
    var invertBetter: Bool = false

    private var difference: Int {
        value1 - value2
    }

    private var percentChange: Double {
        guard value2 > 0 else { return value1 > 0 ? 100 : 0 }
        return Double(difference) / Double(value2) * 100
    }

    private var isBetter: Bool {
        invertBetter ? difference < 0 : difference > 0
    }

    private var iconColor: Color {
        let pageviews = String(localized: "metrics.pageviews")
        let visitors = String(localized: "metrics.visitors")
        let visits = String(localized: "metrics.visits")
        let bounceRate = String(localized: "metrics.bounceRate")

        switch label {
        case pageviews: return .blue
        case visitors: return .purple
        case visits: return .orange
        case bounceRate: return .red
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(iconColor)
                }
            }

            // Periode A Wert
            HStack(spacing: 4) {
                Circle()
                    .fill(.blue)
                    .frame(width: 6, height: 6)
                Text(isPercentage ? "\(value1)%" : value1.formatted())
                    .font(.title3)
                    .fontWeight(.bold)
            }

            // Periode B Wert
            HStack(spacing: 4) {
                Circle()
                    .fill(.orange)
                    .frame(width: 6, height: 6)
                Text(isPercentage ? "\(value2)%" : value2.formatted())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if difference != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: isBetter ? "arrow.up" : "arrow.down")
                        Text(String(format: "%.0f%%", abs(percentChange)))
                    }
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isBetter ? .green : .red)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? iconColor.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? iconColor : .clear, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - ViewModel

@MainActor
class CompareViewModel: ObservableObject {
    let websiteId: String

    @Published var stats1: WebsiteStats?
    @Published var stats2: WebsiteStats?
    @Published var pageviews1: [TimeSeriesPoint] = []
    @Published var pageviews2: [TimeSeriesPoint] = []
    @Published var visitors1: [TimeSeriesPoint] = []
    @Published var visitors2: [TimeSeriesPoint] = []
    @Published var isLoading = false

    private let umamiAPI = UmamiAPI.shared
    private let plausibleAPI = PlausibleAPI.shared

    private var isPlausible: Bool {
        AnalyticsManager.shared.providerType == .plausible
    }

    init(websiteId: String) {
        self.websiteId = websiteId
    }

    func loadComparison(dateRange1: DateRange, dateRange2: DateRange) async {
        isLoading = true

        if isPlausible {
            await loadPlausibleComparison(dateRange1: dateRange1, dateRange2: dateRange2)
        } else {
            await loadUmamiComparison(dateRange1: dateRange1, dateRange2: dateRange2)
        }

        isLoading = false
    }

    private func loadPlausibleComparison(dateRange1: DateRange, dateRange2: DateRange) async {
        do {
            // Fetch stats and timeseries for both periods
            async let s1 = plausibleAPI.getAnalyticsStats(websiteId: websiteId, dateRange: dateRange1)
            async let s2 = plausibleAPI.getAnalyticsStats(websiteId: websiteId, dateRange: dateRange2)
            async let pv1 = plausibleAPI.getPageviewsData(websiteId: websiteId, dateRange: dateRange1)
            async let pv2 = plausibleAPI.getPageviewsData(websiteId: websiteId, dateRange: dateRange2)
            async let v1 = plausibleAPI.getVisitorsData(websiteId: websiteId, dateRange: dateRange1)
            async let v2 = plausibleAPI.getVisitorsData(websiteId: websiteId, dateRange: dateRange2)

            let (analyticsStats1, analyticsStats2, pageviewsData1, pageviewsData2, visitorsData1, visitorsData2) = try await (s1, s2, pv1, pv2, v1, v2)

            // Convert AnalyticsStats to WebsiteStats
            stats1 = WebsiteStats(
                pageviews: StatValue(value: analyticsStats1.pageviews.value, change: analyticsStats1.pageviews.change),
                visitors: StatValue(value: analyticsStats1.visitors.value, change: analyticsStats1.visitors.change),
                visits: StatValue(value: analyticsStats1.visits.value, change: analyticsStats1.visits.change),
                bounces: StatValue(value: analyticsStats1.bounces.value, change: analyticsStats1.bounces.change),
                totaltime: StatValue(value: analyticsStats1.totaltime.value, change: analyticsStats1.totaltime.change)
            )

            stats2 = WebsiteStats(
                pageviews: StatValue(value: analyticsStats2.pageviews.value, change: analyticsStats2.pageviews.change),
                visitors: StatValue(value: analyticsStats2.visitors.value, change: analyticsStats2.visitors.change),
                visits: StatValue(value: analyticsStats2.visits.value, change: analyticsStats2.visits.change),
                bounces: StatValue(value: analyticsStats2.bounces.value, change: analyticsStats2.bounces.change),
                totaltime: StatValue(value: analyticsStats2.totaltime.value, change: analyticsStats2.totaltime.change)
            )

            // Convert AnalyticsChartPoint to TimeSeriesPoint
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            pageviews1 = pageviewsData1.map { TimeSeriesPoint(x: formatter.string(from: $0.date), y: $0.value) }
            pageviews2 = pageviewsData2.map { TimeSeriesPoint(x: formatter.string(from: $0.date), y: $0.value) }
            visitors1 = visitorsData1.map { TimeSeriesPoint(x: formatter.string(from: $0.date), y: $0.value) }
            visitors2 = visitorsData2.map { TimeSeriesPoint(x: formatter.string(from: $0.date), y: $0.value) }

        } catch {
            print("Plausible Compare error: \(error)")
        }
    }

    private func loadUmamiComparison(dateRange1: DateRange, dateRange2: DateRange) async {
        do {
            async let s1 = umamiAPI.getStats(websiteId: websiteId, dateRange: dateRange1)
            async let s2 = umamiAPI.getStats(websiteId: websiteId, dateRange: dateRange2)
            async let pv1 = umamiAPI.getPageviews(websiteId: websiteId, dateRange: dateRange1)
            async let pv2 = umamiAPI.getPageviews(websiteId: websiteId, dateRange: dateRange2)

            let (stats1Result, stats2Result, pageviews1Result, pageviews2Result) = try await (s1, s2, pv1, pv2)

            stats1 = stats1Result
            stats2 = stats2Result
            pageviews1 = pageviews1Result.pageviews
            pageviews2 = pageviews2Result.pageviews
            // Sessions/Visitors Zeitreihe vom gleichen Endpoint
            visitors1 = pageviews1Result.sessions
            visitors2 = pageviews2Result.sessions

        } catch {
            print("Compare error: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        CompareView(
            website: Website(
                id: "1",
                name: "Test",
                domain: "test.de",
                shareId: nil,
            teamId: nil,
                resetAt: nil,
                createdAt: nil
            )
        )
    }
}
