//
//  SimpofocuswidgetControl.swift
//  Simpofocuswidget
//
//  Created by Efe Türkel on 17.10.2025.
//

import AppIntents
import SwiftUI
import WidgetKit

struct SimpofocuswidgetControl: ControlWidget {
    static let kind: String = "com.efeturkel.simpoapp.Simpofocuswidget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetButton(
                "Focus Timer",
                action: StartTimerIntent()
            ) { isPressed in
                Image(systemName: "timer")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
        }
        .displayName("Focus Timer")
        .description("Start Pomodoro timer")
    }
}

extension SimpofocuswidgetControl {
    struct Value {
        var isRunning: Bool
        var name: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: TimerConfiguration) -> Value {
            SimpofocuswidgetControl.Value(isRunning: false, name: configuration.timerName)
        }

        func currentValue(configuration: TimerConfiguration) async throws -> Value {
            let isRunning = false // Default state
            return SimpofocuswidgetControl.Value(isRunning: isRunning, name: configuration.timerName)
        }
    }
}

struct TimerConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Timer Configuration"

    @Parameter(title: "Timer Name", default: "Focus Timer")
    var timerName: String
}
