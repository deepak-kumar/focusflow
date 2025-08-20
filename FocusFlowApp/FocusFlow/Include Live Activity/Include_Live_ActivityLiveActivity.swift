//
//  Include_Live_ActivityLiveActivity.swift
//  Include Live Activity
//
//  Created by deepak kumar on 20/08/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Include_Live_ActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var phase: String // "Focus", "Short Break", "Long Break"
        var remainingTime: TimeInterval // in seconds
        var progress: Double // 0.0 to 1.0
        var isRunning: Bool
    }

    // Fixed non-changing properties about your activity go here!
    var sessionTitle: String // e.g. "Pomodoro Session"
}

struct Include_Live_ActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Include_Live_ActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack(spacing: 12) {
                HStack {
                    // Phase indicator
                    Circle()
                        .fill(phaseColor(for: context.state.phase))
                        .frame(width: 12, height: 12)
                    
                    Text(context.state.phase)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Time remaining
                    Text(formatTime(context.state.remainingTime))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(phaseColor(for: context.state.phase))
                }
                
                // Progress bar
                ProgressView(value: context.state.progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: phaseColor(for: context.state.phase)))
                    .scaleEffect(y: 2)
                
                Text(context.attributes.sessionTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .activityBackgroundTint(Color(.systemBackground))
            .activitySystemActionForegroundColor(phaseColor(for: context.state.phase))

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.phase)
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Circle()
                            .fill(phaseColor(for: context.state.phase))
                            .frame(width: 20, height: 20)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatTime(context.state.remainingTime))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(phaseColor(for: context.state.phase))
                        
                        Text("remaining")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        // Circular progress indicator
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                                .frame(width: 40, height: 40)
                            
                            Circle()
                                .trim(from: 0, to: context.state.progress)
                                .stroke(phaseColor(for: context.state.phase), lineWidth: 6)
                                .frame(width: 40, height: 40)
                                .rotationEffect(.degrees(-90))
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text(context.attributes.sessionTitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if context.state.isRunning {
                                HStack(spacing: 2) {
                                    ForEach(0..<3) { index in
                                        Circle()
                                            .fill(phaseColor(for: context.state.phase))
                                            .frame(width: 4, height: 4)
                                            .opacity(0.6)
                                            .animation(
                                                .easeInOut(duration: 0.6)
                                                .repeatForever(autoreverses: true)
                                                .delay(Double(index) * 0.2),
                                                value: context.state.isRunning
                                            )
                                    }
                                }
                            } else {
                                Text("Paused")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                // Compact leading - phase indicator
                Circle()
                    .fill(phaseColor(for: context.state.phase))
                    .frame(width: 16, height: 16)
            } compactTrailing: {
                // Compact trailing - time remaining
                Text(formatTimeCompact(context.state.remainingTime))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(phaseColor(for: context.state.phase))
            } minimal: {
                // Minimal - just the phase color circle
                Circle()
                    .fill(phaseColor(for: context.state.phase))
                    .frame(width: 12, height: 12)
            }
            .keylineTint(phaseColor(for: context.state.phase))
        }
    }
    
    // MARK: - Helper Functions
    
    private func phaseColor(for phase: String) -> Color {
        switch phase {
        case "Focus":
            return Color(hex: "#7C5CFF") // Purple for focus
        case "Short Break":
            return Color(hex: "#22C55E") // Green for breaks
        case "Long Break":
            return Color(hex: "#0EA5E9") // Blue for long break
        default:
            return .blue
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatTimeCompact(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        if minutes > 0 {
            return String(format: "%dm", minutes)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

// MARK: - Color Extension for Hex Colors

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview Data

extension Include_Live_ActivityAttributes {
    fileprivate static var preview: Include_Live_ActivityAttributes {
        Include_Live_ActivityAttributes(sessionTitle: "Pomodoro Session")
    }
}

extension Include_Live_ActivityAttributes.ContentState {
    fileprivate static var focusSession: Include_Live_ActivityAttributes.ContentState {
        Include_Live_ActivityAttributes.ContentState(
            phase: "Focus",
            remainingTime: 1500, // 25 minutes
            progress: 0.3,
            isRunning: true
        )
    }
     
    fileprivate static var breakSession: Include_Live_ActivityAttributes.ContentState {
        Include_Live_ActivityAttributes.ContentState(
            phase: "Short Break",
            remainingTime: 180, // 3 minutes
            progress: 0.7,
            isRunning: false
        )
    }
}

#Preview("Notification", as: .content, using: Include_Live_ActivityAttributes.preview) {
   Include_Live_ActivityLiveActivity()
} contentStates: {
    Include_Live_ActivityAttributes.ContentState.focusSession
    Include_Live_ActivityAttributes.ContentState.breakSession
}