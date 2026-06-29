import SwiftUI

/// Lightweight celebration particles on workout completion.
struct ConfettiView: View {
    @State private var particles: [Particle] = []
    let isActive: Bool

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var color: Color
        var rotation: Double
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(p.color)
                        .frame(width: 8, height: 14)
                        .rotationEffect(.degrees(p.rotation))
                        .position(x: p.x * geo.size.width, y: p.y * geo.size.height)
                }
            }
            .onChange(of: isActive) { _, active in
                if active { spawn(in: geo.size) }
            }
        }
        .allowsHitTesting(false)
    }

    private func spawn(in size: CGSize) {
        let colors: [Color] = [RepScrollTheme.accent, RepScrollTheme.accentSecondary, RepScrollTheme.success, .white]
        particles = (0..<40).map { _ in
            Particle(
                x: CGFloat.random(in: 0.1...0.9),
                y: CGFloat.random(in: -0.2...0.1),
                color: colors.randomElement()!,
                rotation: Double.random(in: 0...360)
            )
        }
        withAnimation(.easeIn(duration: 1.2)) {
            particles = particles.map {
                var p = $0
                p.y += CGFloat.random(in: 0.8...1.2)
                p.rotation += Double.random(in: 180...720)
                return p
            }
        }
    }
}