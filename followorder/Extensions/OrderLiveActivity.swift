#if os(iOS)
import ActivityKit
import WidgetKit
import SwiftUI

struct OrderAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var statusName: String
        var progress: Double // 0.0 to 1.0
    }
    var orderNumber: String
    var customerName: String
}

struct OrderLiveActivityView: View {
    let context: ActivityViewContext<OrderAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(context.attributes.orderNumber)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(context.state.statusName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.neonCyan)
            }
            
            ProgressView(value: context.state.progress)
                .progressViewStyle(.linear)
                .tint(.neonCyan)
            
            Text("\(context.attributes.customerName) siparişi hazırlanıyor")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.themeBackground)
    }
}

struct OrderLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OrderAttributes.self) { context in
            OrderLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.orderNumber)
                        .font(.caption.bold())
                        .foregroundColor(.neonCyan)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.statusName)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(.neonCyan)
                }
            } compactLeading: {
                Text(context.attributes.orderNumber)
                    .font(.caption2.bold())
                    .foregroundColor(.neonCyan)
            } compactTrailing: {
                Text(context.state.statusName)
                    .font(.caption2.bold())
            } minimal: {
                Image(systemName: "cart.fill")
                    .foregroundColor(.neonCyan)
            }
        }
    }
}
#endif
