// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

#if os(iOS) || os(macOS)

import Foundation
import Combine
import Pulse
import SwiftUI
import CoreData
import Charts

struct InsightsView: View {
    @ObservedObject var viewModel: InsightsViewModel

    private var insights: NetworkLoggerInsights { viewModel.insights }

    var body: some View {
        Form {
            contents
        }
#if os(iOS)
        .navigationTitle("Insights")
#endif
        .onAppear { viewModel.isViewVisible = true }
        .onDisappear { viewModel.isViewVisible = false }
    }

    @ViewBuilder
    private var contents: some View {
        ConsoleSection(isDividerHidden: true, header: { SectionHeaderView(title: "Transfer Size") }) {
            NetworkInspectorTransferInfoView(viewModel: .init(transferSize: insights.transferSize))
                .padding(.vertical, 8)
        }
        durationSection
        if insights.failures.count > 0 {
            failuresSection
        }
        if insights.redirects.count > 0 {
            redirectsSection
        }
    }

    // MARK: - Duration

    private var durationSection: some View {
        ConsoleSection(header: { SectionHeaderView(title: "Duration") }) {
            InfoRow(title: "Median Duration", details: viewModel.medianDuration)
            InfoRow(title: "Duration Range", details: viewModel.durationRange)
            durationChart
#if os(iOS)
            NavigationLink(destination: FocusedListView(title: "Slowest Requests", viewModel: viewModel.makeSlowestRequestsViewModel())) {
                Text("Show Slowest Requests")
            }
#endif
        }
    }

    @ViewBuilder
    private var durationChart: some View {
        if #available(iOS 16, macOS 13, *) {
            if insights.duration.values.isEmpty {
                Text("No network requests yet")
                    .foregroundColor(.secondary)
                    .frame(height: 140)
            } else {
                Chart(viewModel.durationBars) {
                    BarMark(
                        x: .value("Duration", $0.range),
                        y: .value("Count", $0.count)
                    ).foregroundStyle(barMarkColor(for: $0.range.lowerBound))
                }
                .chartXScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 8)) { value in
                        AxisValueLabel() {
                            if let value = value.as(TimeInterval.self) {
                                Text(DurationFormatter.string(from: TimeInterval(value), isPrecise: false))
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .frame(height: 140)
            }
        }
    }

    private func barMarkColor(for duration: TimeInterval) -> Color {
        if duration < 1.0 {
            return Color.green
        } else if duration < 1.9 {
            return Color.yellow
        } else {
            return Color.red
        }
    }

    // MARK: - Redirects

    @ViewBuilder
    private var redirectsSection: some View {
        ConsoleSection(header: {
            SectionHeaderView(systemImage: "exclamationmark.triangle.fill", title: "Redirects")
        }) {
            InfoRow(title: "Redirect Count", details: "\(insights.redirects.count)")
            InfoRow(title: "Total Time Lost", details: DurationFormatter.string(from: insights.redirects.timeLost, isPrecise: false))
#if os(iOS)
            NavigationLink(destination: FocusedListView(title: "Redirects", viewModel: viewModel.makeRequestsWithDedirectsViewModel())) {
                Text("Show Requests with Redirects")
            }
#endif
        }
    }

    // MARK: - Failures

    @ViewBuilder
    private var failuresSection: some View {
        ConsoleSection(header: {
            SectionHeaderView(systemImage: "xmark.octagon.fill", title: "Failures")
        }) {
#if os(iOS)
            NavigationLink(destination: FocusedListView(title: "Failed Requests", viewModel: viewModel.makeFailedRequestsViewModel())) {
                HStack {
                    Text("Failed Requests")
                    Spacer()
                    Text("\(insights.failures.count)")
                        .foregroundColor(.secondary)
                }
            }
#else
            HStack {
                Text("Failed Requests")
                Spacer()
                Text("\(insights.failures.count)")
                    .foregroundColor(.secondary)
            }
#endif
        }
    }
}

#if os(iOS)
struct FocusedListView: View {
    let title: String
    let viewModel: ConsoleViewModel

    var body: some View {
        ConsolePlainList(viewModel: viewModel.listViewModel)
            .inlineNavigationTitle(title)
    }
}
#endif

#if DEBUG
struct NetworkInsightsView_Previews: PreviewProvider {
    static var previews: some View {
            InsightsView(viewModel: .init(store: .mock))
#if os(macOS)
                .frame(width: 320, height: 800)
#endif
    }
}
#endif

#endif
