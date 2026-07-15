import Foundation
import SwiftUI

extension Category {
    public var id: UUID {
        get { idValue ?? UUID() }
        set { idValue = newValue }
    }

    var name: String {
        get { nameValue ?? "" }
        set { nameValue = newValue }
    }

    var colorHex: String {
        get { colorHexValue ?? "8A857C" }
        set { colorHexValue = newValue }
    }

    var color: Color {
        get { Color(hex: colorHex) }
        set { colorHex = newValue.hexString }
    }
}
