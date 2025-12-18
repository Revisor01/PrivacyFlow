import Foundation

@MainActor
class WebsiteDetailViewModel: ObservableObject {
    let websiteId: String

    @Published var stats: WebsiteStats?
    @Published var activeVisitors: Int = 0
    @Published var pageviewsData: [TimeSeriesPoint] = []
    @Published var sessionsData: [TimeSeriesPoint] = []
    @Published var topPages: [MetricItem] = []
    @Published var pageTitles: [MetricItem] = []
    @Published var entryPages: [MetricItem] = []
    @Published var exitPages: [MetricItem] = []
    @Published var referrers: [MetricItem] = []
    @Published var countries: [MetricItem] = []
    @Published var regions: [MetricItem] = []
    @Published var cities: [MetricItem] = []
    @Published var devices: [MetricItem] = []
    @Published var browsers: [MetricItem] = []
    @Published var operatingSystems: [MetricItem] = []
    @Published var languages: [MetricItem] = []
    @Published var screens: [MetricItem] = []
    @Published var events: [MetricItem] = []
    @Published var isLoading = false
    @Published var error: String?

    private let umamiAPI = UmamiAPI.shared
    private let plausibleAPI = PlausibleAPI.shared

    private var isPlausible: Bool {
        AnalyticsManager.shared.providerType == .plausible
    }

    init(websiteId: String) {
        self.websiteId = websiteId
    }

    func loadData(dateRange: DateRange) async {
        isLoading = true
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadStats(dateRange: dateRange) }
            group.addTask { await self.loadActiveVisitors() }
            group.addTask { await self.loadPageviews(dateRange: dateRange) }
            group.addTask { await self.loadTopPages(dateRange: dateRange) }
            group.addTask { await self.loadPageTitles(dateRange: dateRange) }
            group.addTask { await self.loadReferrers(dateRange: dateRange) }
            group.addTask { await self.loadCountries(dateRange: dateRange) }
            group.addTask { await self.loadRegions(dateRange: dateRange) }
            group.addTask { await self.loadCities(dateRange: dateRange) }
            group.addTask { await self.loadDevices(dateRange: dateRange) }
            group.addTask { await self.loadBrowsers(dateRange: dateRange) }
            group.addTask { await self.loadOperatingSystems(dateRange: dateRange) }
            group.addTask { await self.loadLanguages(dateRange: dateRange) }
            group.addTask { await self.loadScreens(dateRange: dateRange) }
            group.addTask { await self.loadEvents(dateRange: dateRange) }
        }
    }

    private func loadStats(dateRange: DateRange) async {
        do {
            if isPlausible {
                let analyticsStats = try await plausibleAPI.getAnalyticsStats(websiteId: websiteId, dateRange: dateRange)
                stats = WebsiteStats(
                    pageviews: StatValue(value: analyticsStats.pageviews.value, change: analyticsStats.pageviews.change),
                    visitors: StatValue(value: analyticsStats.visitors.value, change: analyticsStats.visitors.change),
                    visits: StatValue(value: analyticsStats.visits.value, change: analyticsStats.visits.change),
                    bounces: StatValue(value: analyticsStats.bounces.value, change: analyticsStats.bounces.change),
                    totaltime: StatValue(value: analyticsStats.totaltime.value, change: analyticsStats.totaltime.change)
                )
            } else {
                stats = try await umamiAPI.getStats(websiteId: websiteId, dateRange: dateRange)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadActiveVisitors() async {
        do {
            if isPlausible {
                activeVisitors = try await plausibleAPI.getActiveVisitors(websiteId: websiteId)
            } else {
                activeVisitors = try await umamiAPI.getActiveVisitors(websiteId: websiteId)
            }
        } catch {
            #if DEBUG
            print("Failed to load active visitors: \(error)")
            #endif
        }
    }

    private func loadPageviews(dateRange: DateRange) async {
        do {
            if isPlausible {
                let pageviewData = try await plausibleAPI.getPageviewsData(websiteId: websiteId, dateRange: dateRange)
                let visitorData = try await plausibleAPI.getVisitorsData(websiteId: websiteId, dateRange: dateRange)
                let formatter = ISO8601DateFormatter()
                pageviewsData = fillMissingTimeSlots(
                    data: pageviewData.map { TimeSeriesPoint(x: formatter.string(from: $0.date), y: $0.value) },
                    dateRange: dateRange
                )
                sessionsData = fillMissingTimeSlots(
                    data: visitorData.map { TimeSeriesPoint(x: formatter.string(from: $0.date), y: $0.value) },
                    dateRange: dateRange
                )
            } else {
                let data = try await umamiAPI.getPageviews(websiteId: websiteId, dateRange: dateRange)
                pageviewsData = fillMissingTimeSlots(data: data.pageviews, dateRange: dateRange)
                sessionsData = fillMissingTimeSlots(data: data.sessions, dateRange: dateRange)
            }
        } catch {
            #if DEBUG
            print("Failed to load pageviews: \(error)")
            #endif
        }
    }

    /// Fills in missing time slots with zero values for complete chart display
    private func fillMissingTimeSlots(data: [TimeSeriesPoint], dateRange: DateRange) -> [TimeSeriesPoint] {
        let calendar = Calendar.current
        let now = Date()
        let isHourly = dateRange.unit == "hour"

        // Create a map of existing data by date
        var dataMap: [Date: Int] = [:]
        for point in data {
            dataMap[point.date] = point.value
        }

        var result: [TimeSeriesPoint] = []
        let formatter = ISO8601DateFormatter()

        if isHourly {
            // Generate all hours for the day
            let baseDate: Date
            switch dateRange.preset {
            case .today:
                baseDate = now
            case .yesterday:
                baseDate = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            default:
                baseDate = dateRange.dates.start
            }

            let startOfDay = calendar.startOfDay(for: baseDate)
            let currentHour = dateRange.preset == .today ? calendar.component(.hour, from: now) : 23

            for hour in 0...currentHour {
                if let hourDate = calendar.date(byAdding: .hour, value: hour, to: startOfDay) {
                    // Find matching value in data
                    let value = dataMap.first { existing in
                        calendar.component(.hour, from: existing.key) == hour &&
                        calendar.isDate(existing.key, inSameDayAs: hourDate)
                    }?.value ?? 0

                    result.append(TimeSeriesPoint(x: formatter.string(from: hourDate), y: value))
                }
            }
        } else {
            // Generate all days in range
            let dates = dateRange.dates
            var currentDate = calendar.startOfDay(for: dates.start)
            let endDate = calendar.startOfDay(for: dates.end)

            while currentDate <= endDate {
                // Find matching value in data
                let value = dataMap.first { existing in
                    calendar.isDate(existing.key, inSameDayAs: currentDate)
                }?.value ?? 0

                result.append(TimeSeriesPoint(x: formatter.string(from: currentDate), y: value))

                if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                    currentDate = nextDay
                } else {
                    break
                }
            }
        }

        return result.isEmpty ? data : result
    }

    private func loadTopPages(dateRange: DateRange) async {
        do {
            if isPlausible {
                let items = try await plausibleAPI.getPages(websiteId: websiteId, dateRange: dateRange)
                topPages = items.map { MetricItem(x: $0.name, y: $0.value) }
            } else {
                topPages = try await umamiAPI.getMetrics(websiteId: websiteId, dateRange: dateRange, type: .path, limit: 50)
            }
        } catch {
            #if DEBUG
            print("Failed to load top pages: \(error)")
            #endif
        }
    }

    private func loadPageTitles(dateRange: DateRange) async {
        do {
            if isPlausible {
                // Plausible doesn't have separate page titles, use top pages
                pageTitles = []
            } else {
                pageTitles = try await umamiAPI.getMetrics(websiteId: websiteId, dateRange: dateRange, type: .title, limit: 50)
            }
        } catch {
            #if DEBUG
            print("Failed to load page titles: \(error)")
            #endif
        }
    }

    private func loadReferrers(dateRange: DateRange) async {
        do {
            if isPlausible {
                let items = try await plausibleAPI.getReferrers(websiteId: websiteId, dateRange: dateRange)
                referrers = items.map { MetricItem(x: $0.name, y: $0.value) }
            } else {
                referrers = try await umamiAPI.getMetrics(websiteId: websiteId, dateRange: dateRange, type: .referrer)
            }
        } catch {
            #if DEBUG
            print("Failed to load referrers: \(error)")
            #endif
        }
    }

    private func loadCountries(dateRange: DateRange) async {
        do {
            if isPlausible {
                let items = try await plausibleAPI.getCountries(websiteId: websiteId, dateRange: dateRange)
                countries = items.map { MetricItem(x: $0.name, y: $0.value) }
            } else {
                countries = try await umamiAPI.getMetrics(websiteId: websiteId, dateRange: dateRange, type: .country)
            }
        } catch {
            #if DEBUG
            print("Failed to load countries: \(error)")
            #endif
        }
    }

    private func loadRegions(dateRange: DateRange) async {
        do {
            if isPlausible {
                let items = try await plausibleAPI.getRegions(websiteId: websiteId, dateRange: dateRange)
                regions = items.map { MetricItem(x: $0.name, y: $0.value) }
            } else {
                regions = try await umamiAPI.getMetrics(websiteId: websiteId, dateRange: dateRange, type: .region)
            }
        } catch {
            #if DEBUG
            print("Failed to load regions: \(error)")
            #endif
        }
    }

    private func loadCities(dateRange: DateRange) async {
        do {
            if isPlausible {
                let items = try await plausibleAPI.getCities(websiteId: websiteId, dateRange: dateRange)
                cities = items.map { MetricItem(x: $0.name, y: $0.value) }
            } else {
                cities = try await umamiAPI.getMetrics(websiteId: websiteId, dateRange: dateRange, type: .city)
            }
        } catch {
            #if DEBUG
            print("Failed to load cities: \(error)")
            #endif
        }
    }

    private func loadDevices(dateRange: DateRange) async {
        do {
            if isPlausible {
                let items = try await plausibleAPI.getDevices(websiteId: websiteId, dateRange: dateRange)
                devices = items.map { MetricItem(x: $0.name, y: $0.value) }
            } else {
                devices = try await umamiAPI.getMetrics(websiteId: websiteId, dateRange: dateRange, type: .device)
            }
        } catch {
            #if DEBUG
            print("Failed to load devices: \(error)")
            #endif
        }
    }

    private func loadBrowsers(dateRange: DateRange) async {
        do {
            if isPlausible {
                let items = try await plausibleAPI.getBrowsers(websiteId: websiteId, dateRange: dateRange)
                browsers = items.map { MetricItem(x: $0.name, y: $0.value) }
            } else {
                browsers = try await umamiAPI.getMetrics(websiteId: websiteId, dateRange: dateRange, type: .browser)
            }
        } catch {
            #if DEBUG
            print("Failed to load browsers: \(error)")
            #endif
        }
    }

    private func loadOperatingSystems(dateRange: DateRange) async {
        do {
            if isPlausible {
                let items = try await plausibleAPI.getOS(websiteId: websiteId, dateRange: dateRange)
                operatingSystems = items.map { MetricItem(x: $0.name, y: $0.value) }
            } else {
                operatingSystems = try await umamiAPI.getMetrics(websiteId: websiteId, dateRange: dateRange, type: .os)
            }
        } catch {
            #if DEBUG
            print("Failed to load operating systems: \(error)")
            #endif
        }
    }

    private func loadLanguages(dateRange: DateRange) async {
        do {
            if isPlausible {
                // Plausible doesn't have language breakdown in Stats API v2
                languages = []
            } else {
                languages = try await umamiAPI.getMetrics(websiteId: websiteId, dateRange: dateRange, type: .language)
            }
        } catch {
            #if DEBUG
            print("Failed to load languages: \(error)")
            #endif
        }
    }

    private func loadScreens(dateRange: DateRange) async {
        do {
            if isPlausible {
                // Plausible doesn't have screen size breakdown in Stats API v2
                screens = []
            } else {
                screens = try await umamiAPI.getMetrics(websiteId: websiteId, dateRange: dateRange, type: .screen)
            }
        } catch {
            #if DEBUG
            print("Failed to load screens: \(error)")
            #endif
        }
    }

    private func loadEvents(dateRange: DateRange) async {
        do {
            if isPlausible {
                // Plausible events require different API approach
                events = []
            } else {
                events = try await umamiAPI.getMetrics(websiteId: websiteId, dateRange: dateRange, type: .event)
            }
        } catch {
            #if DEBUG
            print("Failed to load events: \(error)")
            #endif
        }
    }
}
