import SwiftUI
import Combine

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var angle: Double
    var speedY: CGFloat
    var speedX: CGFloat
}

struct ConfettiView: View {
    @Binding var isPresented: Bool
    @State private var particles: [ConfettiParticle] = []
    
    let colors: [Color] = [.neonPurple, .neonCyan, .neonMagenta, .neonLime, .neonBlue, .statusPreparing]
    let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if isPresented {
                    ForEach(particles) { particle in
                        Rectangle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size * 1.6)
                            .rotationEffect(.degrees(particle.angle))
                            .position(x: particle.x, y: particle.y)
                    }
                }
            }
            .onAppear {
                if isPresented {
                    spawnParticles(in: geo.size)
                }
            }
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    spawnParticles(in: geo.size)
                }
            }
            .onReceive(timer) { _ in
                guard isPresented else { return }
                updateParticles(in: geo.size)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    private func spawnParticles(in size: CGSize) {
        let width = size.width > 0 ? size.width : 400
        particles = (0..<100).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 10...width - 10),
                y: CGFloat.random(in: -80...(-10)),
                color: colors.randomElement() ?? .neonPurple,
                size: CGFloat.random(in: 7...14),
                angle: Double.random(in: 0...360),
                speedY: CGFloat.random(in: 5...11),
                speedX: CGFloat.random(in: -2.5...2.5)
            )
        }
    }
    
    private func updateParticles(in size: CGSize) {
        let height = size.height > 0 ? size.height : 800
        var allFinished = true
        for i in 0..<particles.count {
            particles[i].y += particles[i].speedY
            particles[i].x += particles[i].speedX
            particles[i].angle += Double(particles[i].speedY) * 1.8
            
            if particles[i].y < height + 30 {
                allFinished = false
            }
        }
        if allFinished && !particles.isEmpty {
            isPresented = false
        }
    }
}
