import SwiftUI

#if !os(iOS) && !os(tvOS) && !os(watchOS)
// MARK: - Keyboard Type Compatibility for macOS
enum UIKeyboardType {
    case `default`
    case asciiCapable
    case numbersAndPunctuation
    case URL
    case numberPad
    case phonePad
    case namePhonePad
    case emailAddress
    case decimalPad
    case twitter
    case webSearch
    case asciiCapableNumberPad
}

extension View {
    func keyboardType(_ type: UIKeyboardType) -> some View {
        self
    }
}
#endif


// MARK: - Picker Style Compatibility for macOS
extension Picker {
    @ViewBuilder
    func adaptivePickerStyle() -> some View {
        #if os(iOS)
        self.pickerStyle(.navigationLink)
        #else
        self.pickerStyle(.menu)
        #endif
    }
}
