import SwiftUI

struct LoyaltyStampCard: View {
    var stampsCount: Int // 0 to 10
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LOYALTY STAMP CARD")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.goldenYellow)
                        .tracking(1)
                    Text("Sciascia 1919 Privilege")
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.textPrimary)
                }
                Spacer()
                Text("\(stampsCount)/10 Stamps")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.creamyLatte)
                    .cornerRadius(10)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 12) {
                ForEach(0..<10) { index in
                    ZStack {
                        Circle()
                            .fill(Color.themeBackground.opacity(0.5))
                            .frame(height: 52)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        index < stampsCount ? Color.goldenYellow : Color.textPrimary.opacity(0.12),
                                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: index < stampsCount ? [] : [4, 4])
                                    )
                            )
                        
                        if index < stampsCount {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.textPrimary)
                                .shadow(color: .goldenYellow.opacity(0.55), radius: 6, x: 0, y: 0)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textPrimary.opacity(0.3))
                        }
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.6).delay(Double(index) * 0.05), value: stampsCount)
                }
            }
            .padding(.top, 8)
            
            Text("Earn 1 stamp for each drink purchase. Get your 10th cup for free!")
                .font(.system(size: 9))
                .foregroundColor(.textSecondary)
                .padding(.top, 4)
        }
        .padding(16)
        .glassCard(accentColor: .goldenYellow)
    }
}

#Preview {
    LoyaltyStampCard(stampsCount: 6)
        .background(Color.themeBackground)
}
