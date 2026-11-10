struct ReminderContent {
    let name: String
    let heading: String
    let detail: String
    let acknowledgement: String
    let compactTitle: String
    let idleHeading: String
    let pendingDescription: String
    let menuSymbol: String

    init(kind: ReminderKind) {
        switch kind {
        case .posture:
            name = "Duduk tegak"
            heading = "Yuk, duduk lebih tegak."
            detail = "Rilekskan bahu dan sesuaikan posisi dudukmu."
            acknowledgement = "Sudah tegak"
            compactTitle = "Postur"
            idleHeading = "Ambil posisi nyaman."
            pendingDescription = "Saatnya menyesuaikan posisi duduk"
            menuSymbol = "figure.seated.side"
        case .water:
            name = "Minum air putih"
            heading = "Yuk, minum air putih."
            detail = "Ambil jeda sebentar untuk minum air putih."
            acknowledgement = "Sudah minum"
            compactTitle = "Minum"
            idleHeading = "Siapkan air minummu."
            pendingDescription = "Saatnya minum air putih"
            menuSymbol = "drop"
        }
    }
}
