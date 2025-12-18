import SwiftUI

struct DashboardSettingsView: View {
    @ObservedObject private var settingsManager = DashboardSettingsManager.shared

    var body: some View {
        List {
            Section {
                Toggle(isOn: $settingsManager.showGraph) {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                            .frame(width: 28, height: 28)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Text("dashboard.settings.showGraph")
                    }
                }
            } header: {
                Text("dashboard.settings.graph")
            } footer: {
                Text("dashboard.settings.graph.footer")
            }

            Section {
                ForEach(DashboardMetric.allCases) { metric in
                    MetricToggleRow(
                        metric: metric,
                        isEnabled: settingsManager.isEnabled(metric),
                        canDisable: settingsManager.enabledMetrics.count > 1,
                        onToggle: {
                            settingsManager.toggle(metric)
                        }
                    )
                }
            } header: {
                Text("dashboard.settings.metrics")
            } footer: {
                Text("dashboard.settings.metrics.footer")
            }
        }
        .navigationTitle("dashboard.settings.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MetricToggleRow: View {
    let metric: DashboardMetric
    let isEnabled: Bool
    let canDisable: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: {
            if isEnabled && !canDisable {
                // Can't disable the last metric
                return
            }
            onToggle()
        }) {
            HStack(spacing: 12) {
                Image(systemName: metric.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(metric.iconColor)
                    .frame(width: 28, height: 28)
                    .background(metric.iconColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(metric.localizedName)
                    .foregroundStyle(.primary)

                Spacer()

                if isEnabled {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                        .fontWeight(.semibold)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled || canDisable ? 1 : 0.5)
    }
}

#Preview {
    NavigationStack {
        DashboardSettingsView()
    }
}
