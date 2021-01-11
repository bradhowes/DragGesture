// Copyright © 2021 Brad Howes. All rights reserved.

import SwiftUI

public struct KnobView: View {
    @Environment(\.knobStyle) var style: AnyKnobStyle
    @Environment(\.knobAttributes) var attributes: KnobAttributes

    let label: String
    @Binding var value: CGFloat
    let minValue: CGFloat
    let maxValue: CGFloat

    public init(label: String, value: Binding<CGFloat>, minValue: CGFloat = 0.0, maxValue: CGFloat = 1.0) {
        self.label = label
        self._value = value
        self.minValue = minValue
        self.maxValue = maxValue
    }

    public var body: some View {
        let config = KnobConfig(label: label, value: _value, minValue: minValue, maxValue: maxValue, attributes: attributes)
        return style.makeBody(config: config)
    }
}

public struct KnobConfig {
    public var label: String
    @Binding public var value: CGFloat
    public var minValue: CGFloat
    public var maxValue: CGFloat
    public var attributes: KnobAttributes
}

public struct KnobAttributes {
    public var size: CGFloat
    public var trackColor: Color
    public var trackStyle: StrokeStyle

    public var progressColor: Color
    public var progressStyle: StrokeStyle

    public var indicatorFraction: CGFloat
    public var trackingSensitivity: CGFloat

    public var valueFormatter: (CGFloat) -> String
    public var labelGenerator: (String) -> Text

    public init(size: CGFloat = 100.0,
                trackColor: Color = Color(white: 1.0 / 3.0),
                trackStyle: StrokeStyle = StrokeStyle(lineWidth: 4.0, lineCap: .round, lineJoin: .round),
                progressColor: Color = Color(red: 100.0 / 255.0, green: 210.0 / 255.0, blue: 1.0),
                progressStyle: StrokeStyle = StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round),
                indicatorFraction: CGFloat = 0.3,
                trackingSensitivity: CGFloat = 2.0,
                valueFormatter: ((CGFloat) -> String)? = nil,
                labelGenerator: ((String) -> Text)? = nil) {
        self.size = size
        self.trackColor = trackColor
        self.trackStyle = trackStyle
        self.progressColor = progressColor
        self.progressStyle = progressStyle
        self.indicatorFraction = indicatorFraction
        self.trackingSensitivity = trackingSensitivity
        self.valueFormatter = valueFormatter ?? { value in String(format: "%.2f", value) + "s" }
        self.labelGenerator = labelGenerator ?? { value in Text(value).foregroundColor(progressColor) }
    }
}

public protocol KnobStyle {
    associatedtype Body : View

    func makeBody(config: Self.Config) -> Self.Body

    typealias Config = KnobConfig
}

extension KnobStyle {
    public func makeBodyTypeErased(config: Self.Config) -> AnyView {
        AnyView(self.makeBody(config: config))
    }
}

extension EnvironmentValues {
    public var knobStyle: AnyKnobStyle {
        get { self[KnobStyleKey.self] }
        set { self[KnobStyleKey.self] = newValue }
    }

    public var knobAttributes: KnobAttributes {
        get { self[KnobAttributesKey.self] }
        set { self[KnobAttributesKey.self] = newValue }
    }
}

public struct KnobStyleKey: EnvironmentKey {
    public static let defaultValue: AnyKnobStyle = AnyKnobStyle(DefaultKnobStyle())
}

public struct KnobAttributesKey: EnvironmentKey {
    public static let defaultValue: KnobAttributes = KnobAttributes()
}

extension View {
    public func knobStyle<S>(_ style: S) -> some View where S: KnobStyle {
        self.environment(\.knobStyle, AnyKnobStyle(style))
    }

    public func knobAttributes(_ attributes: KnobAttributes) -> some View {
        self.environment(\.knobAttributes, attributes)
    }
}

public struct AnyKnobStyle: KnobStyle {
    private let _makeBody: (KnobStyle.Config) -> AnyView

    public init<Style: KnobStyle>(_ style: Style) { self._makeBody = style.makeBodyTypeErased }

    public func makeBody(config: KnobStyle.Config) -> AnyView { _makeBody(config) }
}

public struct DefaultKnobStyle: KnobStyle {
    public func makeBody(config: Self.Config) -> DefaultKnobView {
        DefaultKnobView(config: config)
    }
}

public struct DefaultKnobView: View {
    public let config: KnobConfig

    private enum DragState: Equatable {
        case inactive
        case pressing
        case dragging

        var isActive: Bool {
            switch self {
            case .inactive: return false
            case .pressing, .dragging: return true
            }
        }

        var isDragging: Bool {
            switch self {
            case .inactive, .pressing: return false
            case .dragging: return true
            }
        }
    }

    @GestureState private var dragState = DragState.inactive
    @State private var manipulated: Bool = false
    @State private var previous = CGPoint.zero
    @State private var resetShowValueTimer: Timer? = nil

    public var body: some View {
        let ratio = (config.maxValue - config.minValue) / (config.attributes.size * config.attributes.trackingSensitivity)
        let minimumLongPressDuration = 0.01
        let longPressDrag = LongPressGesture(minimumDuration: minimumLongPressDuration)
            .sequenced(before: DragGesture())
            .updating($dragState) { gestureValue, dragState, _ in
                switch gestureValue {
                case .first(true): dragState = .pressing
                case .second(true, _): dragState = .dragging
                default: dragState = .inactive
                }
            }
            .onChanged { gestureValue in
                switch gestureValue {
                case .first(true): setManipulated(true)
                case .second(true, let gestureValue):
                    guard let value = gestureValue else {
                        previous = CGPoint.zero
                        return
                    }

                    if previous != .zero {
                        let deltaX = abs(value.location.x - previous.x)
                        let deltaY = -(value.location.y - previous.y)
                        let scaleT = CGFloat(log10(max(deltaX, 1.0)) + 1)
                        config.value = max(config.minValue, min(config.maxValue, config.value + deltaY / scaleT * ratio))
                    }
                    previous = CGPoint(x: value.startLocation.x, y: value.location.y)

                default: setManipulated(false)
                }
            }
            .onEnded { _ in
                setManipulated(false)
            }

        VStack(spacing: -4) {
            ZStack {
                KnobShape(indicatorFraction: config.attributes.indicatorFraction)
                    .stroke(config.attributes.trackColor, style: config.attributes.trackStyle)
                KnobShape(indicatorFraction: config.attributes.indicatorFraction, progress: config.value)
                    .stroke(config.attributes.progressColor, style: config.attributes.progressStyle)
            }
            label
        }
        .frame(width: config.attributes.size, height: config.attributes.size)
        .contentShape(Rectangle()) // Necessary to capture touch events inside control
        .gesture(longPressDrag)
    }

    private var label: Text {
        if manipulated {
            return config.attributes.labelGenerator(config.attributes.valueFormatter(config.value))
        }
        else {
            return config.attributes.labelGenerator(config.label)
        }
    }

    private func setManipulated(_ value: Bool) {
        print("setShowValue \(value) \(dragState)")
        if value {
            manipulated = value
        }
        resetShowValueTimer?.invalidate()
        resetShowValueTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            if dragState == .inactive {
                withAnimation {
                    manipulated = false
                }
            }
            else {
                setManipulated(true)
            }
        }
    }

    private struct KnobShape: Shape {
        private let indicatorFraction: CGFloat
        private let startAngle: Angle
        private let endAngle: Angle
        private let hasIndicator: Bool

        public init(indicatorFraction: CGFloat) {
            self.indicatorFraction = indicatorFraction
            self.startAngle = Angle(degrees: 130.0)
            self.endAngle = Angle(degrees: 410.0)
            self.hasIndicator = false
        }

        public init(indicatorFraction: CGFloat, progress: CGFloat) {
            self.indicatorFraction = indicatorFraction
            self.startAngle = Angle(degrees: 130.0)
            self.endAngle = Angle(degrees: Double(130.0 + (410.0 - 130.0) * progress))
            self.hasIndicator = true
        }

        public func path(in rect: CGRect) -> Path {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) * 0.5 - 10.0
            var path = Path()
            path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            if hasIndicator {
                if let pos = path.currentPoint {
                    path.addLine(to: CGPoint(x: pos.x - (pos.x - center.x) * indicatorFraction, y: pos.y - (pos.y - center.y) * indicatorFraction))
                }
            }
            return path
        }
    }
}

struct KnobView_Previews: PreviewProvider {
    @State private static var value: CGFloat = 0.45
    @State private static var manipulatedFalse: Bool = false

    static var previews: some View {
        Group {
            KnobView(label: "One", value: $value)
                .preferredColorScheme(.dark)
            KnobView(label: "One", value: $value)
                .knobAttributes(KnobAttributes(progressColor: .yellow))
                .preferredColorScheme(.dark)
        }
        .knobAttributes(KnobAttributes(trackColor: .red))
    }
}
