import SwiftUI

struct LuxuryLaunchScreen: View {
    @State private var isAnimatingIcon = false
    @State private var isAnimatingText = false

    var body: some View {
        ZStack {
            // High-end dark ambient background
            Color(red: 0.05, green: 0.05, blue: 0.06)
                .ignoresSafeArea()
            
            // Subtle ambient glows
            RadialGradient(
                colors: [Color.white.opacity(0.08), .clear],
                center: .topLeading,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color("ForestGreen").opacity(0.15), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Focus / Minimalist Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.01))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle().strokeBorder(Color.white.opacity(isAnimatingIcon ? 0.3 : 0.0), lineWidth: 0.5)
                        )
                    
                    Image(systemName: "timer")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundStyle(Color.white)
                        .scaleEffect(isAnimatingIcon ? 1.0 : 0.8)
                        .opacity(isAnimatingIcon ? 1.0 : 0.0)
                }

                // Brand Name
                VStack(spacing: 8) {
                    Text("SIMPO")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .tracking(8)
                        .foregroundStyle(.white)
                    
                    Text("FOCUS")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .tracking(16)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .opacity(isAnimatingText ? 1.0 : 0.0)
                .offset(y: isAnimatingText ? 0 : 20)
            }
        }
        .onAppear {
            // Orchestrate the billion-dollar reveal
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                isAnimatingIcon = true
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8)) {
                isAnimatingText = true
            }
        }
    }
}
