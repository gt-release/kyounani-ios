#if canImport(SwiftUI)
import SwiftUI

#if canImport(UIKit)
import UIKit

public struct ParentalGateTriggerArea: UIViewRepresentable {
    private let onTriggered: () -> Void

    public init(onTriggered: @escaping () -> Void) {
        self.onTriggered = onTriggered
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onTriggered: onTriggered)
    }

    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let recognizer = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        recognizer.numberOfTouchesRequired = 3
        recognizer.minimumPressDuration = 2.0
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)

        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}

    public final class Coordinator: NSObject {
        private let onTriggered: () -> Void

        init(onTriggered: @escaping () -> Void) {
            self.onTriggered = onTriggered
        }

        @objc
        func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard recognizer.state == .began else { return }
            onTriggered()
        }
    }
}
#else
public struct ParentalGateTriggerArea: View {
    private let onTriggered: () -> Void

    public init(onTriggered: @escaping () -> Void) {
        self.onTriggered = onTriggered
    }

    public var body: some View {
        Color.clear
    }
}
#endif

#endif
