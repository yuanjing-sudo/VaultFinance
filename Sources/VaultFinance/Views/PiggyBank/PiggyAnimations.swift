import Foundation
import SwiftUI

// MARK: - Animated Piggy Bank
// A fully custom-drawn, animated piggy bank. Grows fatter with savings,
// breathes gently, bounces on deposit, drops coins, and celebrates level-ups.

struct AnimatedPiggyBank: View {
    var progress: Double            // 0...1
    var themeColor: Color = VaultTheme.orange
    var isBroken: Bool = false
    var isCelebrating: Bool = false

    @State private var breathe: CGFloat = 1.0
    @State private var bounce: CGFloat = 1.0
    @State private var eyeBlink: Bool = false
    @State private var wiggle: Double = 0
    @State private var coinDrop: Bool = false
    @AppStorage("vault.reduceMotion") private var reduceMotion = false

    // Fatness: 0.80 (skinny) → 1.45 (very fat)
    private var fatness: CGFloat { CGFloat(0.80 + 0.65 * max(0, min(progress, 1))) }

    var body: some View {
        ZStack {
            // Glow / bubble
            Circle()
                .fill(
                    RadialGradient(
                        colors: [themeColor.opacity(0.22), themeColor.opacity(0.02)],
                        center: .center, startRadius: 8, endRadius: 130
                    )
                )
                .frame(width: 250, height: 250)
                .scaleEffect(1 + (breathe - 1) * 0.5)

            // Coin fountain when celebrating
            if isCelebrating {
                CoinBurst(color: VaultTheme.gold)
                    .offset(y: -10)
            }

            // The piggy body
            PiggyBody(fatness: fatness, themeColor: themeColor, blink: eyeBlink, broken: isBroken)
                .frame(width: 200 * fatness, height: 160 * fatness)
                .scaleEffect(bounce)
                .rotationEffect(.degrees(wiggle))
                .shadow(color: themeColor.opacity(0.35), radius: 12, x: 0, y: 8)

            // Falling coin on deposit
            if coinDrop {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(VaultTheme.gold)
                    .offset(y: -60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            if !reduceMotion { startBreathing() }
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced {
                withAnimation(.easeOut(duration: 0.2)) {
                    breathe = 1.0
                    bounce = 1.0
                    wiggle = 0
                    coinDrop = false
                    eyeBlink = false
                }
            } else {
                startBreathing()
            }
        }
        .onChange(of: progress) { _, _ in
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.4)) { bounce = 1.12 }
            coinDrop = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { bounce = 1.0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.3)) { coinDrop = false }
            }
            withAnimation(.easeInOut(duration: 0.3)) { wiggle = 6 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) { wiggle = -6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.3)) { wiggle = 0 }
            }
        }
        .accessibilityLabel("Piggy bank \(Int(progress * 100)) percent full")
    }

    private func startBreathing() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            breathe = 1.04
        }
        scheduleBlink()
    }

    private func scheduleBlink() {
        guard !reduceMotion else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.5...5.0)) {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.08)) { eyeBlink = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.08)) { eyeBlink = false }
                scheduleBlink()
            }
        }
    }
}

// MARK: - Piggy Body Shape

struct PiggyBody: View {
    var fatness: CGFloat
    var themeColor: Color
    var blink: Bool
    var broken: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Shadow ellipse
                Ellipse()
                    .fill(Color.black.opacity(0.12))
                    .frame(width: w * 0.85, height: h * 0.16)
                    .offset(y: h * 0.46)

                // Ears
                PiggyEar(color: themeColor)
                    .frame(width: w * 0.22, height: h * 0.26)
                    .offset(x: -w * 0.22, y: -h * 0.30)
                PiggyEar(color: themeColor)
                    .frame(width: w * 0.22, height: h * 0.26)
                    .offset(x: w * 0.10, y: -h * 0.32)

                // Legs
                PiggyLeg(color: themeColor)
                    .frame(width: w * 0.14, height: h * 0.20)
                    .offset(x: -w * 0.22, y: h * 0.36)
                PiggyLeg(color: themeColor)
                    .frame(width: w * 0.14, height: h * 0.20)
                    .offset(x: w * 0.18, y: h * 0.36)

                // Body
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [themeColor.opacity(0.95), themeColor.opacity(0.70)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Ellipse().stroke(Color.white.opacity(0.35), lineWidth: 2)
                    )
                    .frame(width: w * 0.78, height: h * 0.62)
                    .offset(y: h * 0.02)

                // Belly highlight
                Ellipse()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: w * 0.34, height: h * 0.26)
                    .offset(x: -w * 0.10, y: h * 0.10)

                // Coin slot
                Capsule()
                    .fill(Color.black.opacity(0.35))
                    .frame(width: w * 0.20, height: h * 0.05)
                    .offset(y: -h * 0.10)

                // Snout
                Ellipse()
                    .fill(themeColor.opacity(0.85))
                    .frame(width: w * 0.22, height: h * 0.18)
                    .offset(x: w * 0.34, y: h * 0.02)
                    .overlay(
                        HStack(spacing: w * 0.03) {
                            Circle().fill(Color.black.opacity(0.45)).frame(width: w * 0.03, height: w * 0.03)
                            Circle().fill(Color.black.opacity(0.45)).frame(width: w * 0.03, height: w * 0.03)
                        }
                        .offset(x: w * 0.34, y: h * 0.02)
                    )

                // Eyes
                PiggyEye(blink: blink)
                    .frame(width: w * 0.07, height: w * 0.07)
                    .offset(x: w * 0.10, y: -h * 0.12)
                PiggyEye(blink: blink)
                    .frame(width: w * 0.07, height: w * 0.07)
                    .offset(x: w * 0.26, y: -h * 0.12)

                // Curly tail
                TailShape()
                    .stroke(themeColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: w * 0.14, height: h * 0.14)
                    .offset(x: -w * 0.40, y: h * 0.02)

                // Broken overlay
                if broken {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: w * 0.12))
                        .foregroundColor(.white.opacity(0.9))
                        .rotationEffect(.degrees(-25))
                        .offset(x: w * 0.05, y: -h * 0.18)
                }
            }
        }
    }
}

struct PiggyEar: View {
    var color: Color
    var body: some View {
        Triangle()
            .fill(color.opacity(0.85))
            .overlay(Triangle().stroke(Color.white.opacity(0.25), lineWidth: 1.5))
    }
}

struct PiggyLeg: View {
    var color: Color
    var body: some View {
        Capsule()
            .fill(color.opacity(0.8))
    }
}

struct PiggyEye: View {
    var blink: Bool
    var body: some View {
        Group {
            if blink {
                Capsule().fill(Color.black.opacity(0.8)).frame(height: 2)
            } else {
                ZStack {
                    Circle().fill(Color.white)
                    Circle().fill(Color.black).frame(width: 5, height: 5)
                }
            }
        }
    }
}

// MARK: - Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct TailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control1: CGPoint(x: rect.maxX, y: rect.minY - rect.height * 0.3),
            control2: CGPoint(x: rect.minX, y: rect.maxY + rect.height * 0.3)
        )
        return p
    }
}

// MARK: - Coin Burst

struct CoinBurst: View {
    var color: Color
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { i in
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: CGFloat.random(in: 10...18)))
                    .foregroundColor(color)
                    .offset(
                        x: animate ? CGFloat.random(in: -90...90) : 0,
                        y: animate ? CGFloat.random(in: -120 ... -40) : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .rotationEffect(.degrees(animate ? Double.random(in: -90...90) : 0))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) { animate = true }
        }
    }
}

// MARK: - Floating Coin Particle

struct FloatingCoin: View {
    var delay: Double
    @State private var rise = false

    var body: some View {
        Image(systemName: "dollarsign.circle.fill")
            .font(.system(size: 14))
            .foregroundColor(VaultTheme.gold.opacity(0.7))
            .offset(y: rise ? -70 : 0)
            .opacity(rise ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 2.2).repeatForever(autoreverses: false).delay(delay)) {
                    rise = true
                }
            }
    }
}

// MARK: - Streak Flame

struct AnimatedStreakFlame: View {
    var streak: Int
    @State private var flicker: CGFloat = 1.0

    private var scale: CGFloat {
        // Flame grows with streak, capped
        min(1.0 + CGFloat(streak) * 0.04, 1.8)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.orange.opacity(0.35), Color.clear],
                        center: .center, startRadius: 2, endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .scaleEffect(flicker)

            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange, .red], startPoint: .top, endPoint: .bottom)
                )
                .scaleEffect(scale * flicker)
                .shadow(color: .orange.opacity(0.6), radius: 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                flicker = 1.08
            }
        }
    }
}
