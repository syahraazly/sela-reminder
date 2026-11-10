public struct SettingsViewState {
    public static let presetMinutes = [15, 30, 45, 60]
    public static let reminderOptions = ReminderKind.allCases.map {
        ReminderKindOption(kind: $0, title: ReminderContent(kind: $0).name)
    }

    public let countdown: String
    public let caption: String
    public let status: String
    public let primaryTitle: String
    public let selectedInterval: Int
    public let intervalInput: String
    public let isEditingInterval: Bool
    public let hint: String
    public let hasInputError: Bool
    public let soundEnabled: Bool
    public let selectedReminderKind: ReminderKind
}

public struct ReminderKindOption: Sendable {
    public let kind: ReminderKind
    public let title: String
}

public struct IslandViewState {
    public let isExpanded: Bool
    public let compactTitle: String
    public let heading: String
    public let subtitle: String
    public let primaryTitle: String
    public let secondaryTitle: String
}

public struct MenuBarViewState {
    public let status: String
    public let primaryTitle: String
    public let toolTip: String
    public let symbolName: String
    public let accessibilityLabel: String
}
