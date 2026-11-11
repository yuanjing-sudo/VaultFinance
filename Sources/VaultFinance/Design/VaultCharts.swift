import Foundation
import SwiftUI

// MARK: - VaultCharts
// Dependency-free, animated, cross-platform SwiftUI charts.

// MARK: - Chart Data Point

struct ChartPoint: Identifiable, Hashable {
    let id = UUID()
    var x: Double
    var y: Double
    var label: String? = nil
}

// MARK: - Line / Area Chart

struct VaultLineChart: View {
    var points: [ChartPoint]
    var tint: Color = VaultTheme.blue
    var showArea: Bool = true
    var showDots: Bool = false
    var lineWidth: CGFloat = 2.5

    @State private var reveal: CGFloat = 0

    private var normalized: [(x: CGFloat, y: CGFloat)] {
        guard points.count > 1 else { return [] }
        let ys = points.map { $0.y }
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 1
        let range = max(maxY - minY, 0.0001)
        return points.map { p in
            let nx = CGFloat(p.x)
            let ny = 1 - CGFloat((p.y - minY) / range)
            return (nx, ny)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let pts = normalized
            if pts.isEmpty {
                VaultEmptyState(icon: "chart.line.uptrend.xyaxis", title: "No data")
            } else {
                ZStack {
                    if showArea {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: geo.size.height))
                            for (i, p) in pts.enumerated() {
                                let x = p.x * geo.size.width
                                let y = p.y * geo.size.height
                                if i == 0 { path.addLine(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.35), tint.opacity(0.02)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .opacity(Double(reveal))
                    }

                    Path { path in
                        for (i, p) in pts.enumerated() {
                            let x = p.x * geo.size.width
                            let y = p.y * geo.size.height
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .trim(from: 0, to: reveal)
                    .stroke(
                        LinearGradient(colors: [tint.opacity(0.6), tint], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )

                    if showDots {
                        ForEach(pts.indices, id: \.self) { i in
                            let p = pts[i]
                            Circle()
                                .fill(tint)
                                .frame(width: 6, height: 6)
                                .position(x: p.x * geo.size.width, y: p.y * geo.size.height)
                                .opacity(Double(reveal))
                        }
                    }
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.1)) { reveal = 1 }
                }
            }
        }
    }
}

// MARK: - Bar Chart

struct VaultBarChart: View {
    var values: [Double]
    var labels: [String] = []
    var tint: Color = VaultTheme.blue
    var height: CGFloat = 160
    var showValues: Bool = false

    @State private var reveal: CGFloat = 0

    private var maxValue: Double { max(values.max() ?? 1, 1) }

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: max(4, geo.size.width / CGFloat(max(values.count, 1)) * 0.18)) {
                ForEach(values.indices, id: \.self) { index in
                    let value = values[index]
                    VStack(spacing: 6) {
                        if showValues {
                            Text("\(value, specifier: "%.0f")")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                LinearGradient(colors: [tint.opacity(0.6), tint], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(
                                width: max(6, (geo.size.width / CGFloat(max(values.count, 1))) * 0.58),
                                height: max(6, CGFloat(value / maxValue) * (geo.size.height - 24)) * reveal
                            )
                        if index < labels.count {
                            Text(labels[index])
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: geo.size.height, alignment: .bottom)
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { reveal = 1 }
            }
        }
        .frame(height: height)
    }
}

// MARK: - Donut Chart

struct DonutSlice: Identifiable, Hashable {
    let id = UUID()
    var label: String
    var value: Double
    var color: Color
}

struct VaultDonutChart: View {
    var slices: [DonutSlice]
    var lineWidth: CGFloat = 22
    var centerTitle: String? = nil
    var centerSubtitle: String? = nil

    @State private var reveal: CGFloat = 0

    private var total: Double { max(slices.reduce(0) { $0 + $1.value }, 0.0001) }

    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.12), lineWidth: lineWidth)

            ForEach(slices.indices, id: \.self) { index in
                let slice = slices[index]
                let prior = slices.prefix(index).reduce(0) { $0 + $1.value } / total
                let fraction = slice.value / total
                Circle()
                    .trim(from: prior * reveal, to: (prior + fraction) * reveal)
                    .stroke(slice.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }

            if let centerTitle {
                VStack(spacing: 2) {
                    Text(centerTitle).font(.headline).bold()
                    if let centerSubtitle {
                        Text(centerSubtitle).font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) { reveal = 1 }
        }
    }
}

// MARK: - Sparkline

struct VaultSparkline: View {
    var values: [Double]
    var tint: Color = VaultTheme.green

    var body: some View {
        GeometryReader { geo in
            let norm = normalize(values)
            Path { path in
                for (i, p) in norm.enumerated() {
                    let x = CGFloat(i) / CGFloat(max(norm.count - 1, 1)) * geo.size.width
                    let y = (1 - p) * geo.size.height
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }

    private func normalize(_ v: [Double]) -> [CGFloat] {
        guard let mn = v.min(), let mx = v.max(), mx > mn else {
            return v.map { _ in 0.5 }
        }
        let range = mx - mn
        return v.map { CGFloat(($0 - mn) / range) }
    }
}

// MARK: - Ring Gauge

struct VaultGauge: View {
    var value: Double          // 0...1
    var tint: Color = VaultTheme.blue
    var label: String = ""
    var valueText: String = ""

    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.15), lineWidth: 14)
            Circle()
                .trim(from: 0, to: max(0, min(value, 1)))
                .stroke(
                    AngularGradient(colors: [tint.opacity(0.5), tint], center: .center),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.9), value: value)
            VStack(spacing: 2) {
                Text(valueText).font(.title3).bold()
                Text(label).font(.caption2).foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Heatmap Grid

struct HeatmapCell: Identifiable, Hashable {
    let id = UUID()
    var row: Int
    var col: Int
    var intensity: Double   // 0...1
    var label: String
    var detail: String
}

struct VaultHeatmap: View {
    var cells: [HeatmapCell]
    var rows: Int
    var columns: Int
    var tint: Color = VaultTheme.green
    var cellSize: CGFloat = 16

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: 4) {
                    ForEach(0..<columns, id: \.self) { c in
                        let cell = cells.first { $0.row == r && $0.col == c }
                        RoundedRectangle(cornerRadius: 3)
                            .fill(tint.opacity(0.08 + 0.85 * (cell?.intensity ?? 0)))
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }
}

// MARK: - Stacked Bar

struct VaultStackedBar: View {
    var segments: [DonutSlice]
    var height: CGFloat = 14

    private var total: Double { max(segments.reduce(0) { $0 + $1.value }, 0.0001) }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(segments) { seg in
                    Rectangle()
                        .fill(seg.color)
                        .frame(width: max(0, CGFloat(seg.value / total) * geo.size.width))
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: height)
    }
}

// MARK: - Animated Number

struct AnimatedNumber: View {
    var value: Double
    var prefix: String = ""
    var suffix: String = ""
    var decimals: Int = 0
    var font: Font = .title2

    @State private var display: Double = 0

    var body: some View {
        Text("\(prefix)\(formatted(display))\(suffix)")
            .font(font).bold()
            .onAppear {
                withAnimation(.easeOut(duration: 0.9)) { display = value }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeOut(duration: 0.9)) { display = newValue }
            }
    }

    private func formatted(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = decimals
        f.maximumFractionDigits = decimals
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }
}
