import TipKit

struct QuickOrderTip: Tip {
    var title: Text {
        Text("Quick Customer Selections")
            .foregroundColor(.textPrimary)
            .bold()
    }
    
    var message: Text? {
        Text("Tap any customer name at the top of the ordering panel to immediately assign the order and review their loyalty stamp status.")
            .foregroundColor(.textSecondary)
    }
    
    var image: Image? {
        Image(systemName: "person.badge.plus.fill")
    }
}
