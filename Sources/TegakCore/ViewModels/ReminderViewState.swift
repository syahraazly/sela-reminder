public struct SettingsViewState {
    public static let presetMinutes = [15, 30, 45, 60]

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
}
