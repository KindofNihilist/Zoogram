//
//  Colorscheme.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 29.01.2022.
//

import UIKit

typealias Gradient = [CGColor]

protocol CatNoseColorScheme: Sendable {
    var noseColor: UIColor { get }
    var bridgeGradient: Gradient { get }
    var nostrilGradient: Gradient { get }
}

struct GrayCatNose: CatNoseColorScheme {

    private static var noseBridgeGradientFirstColor: UIColor {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.00)
            case .light:
                return UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.00)
            default:
                return UIColor.blue
            }
        }
    }

    private static var noseBridgeGradientSecondColor: UIColor {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.28, green: 0.28, blue: 0.28, alpha: 1.00)
            case .light:
                return UIColor(red: 0.30, green: 0.30, blue: 0.30, alpha: 1.00)
            default:
                return UIColor.blue
            }
        }
    }

    private static var nostrilGradientFirstColor: UIColor {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.00)
            case .light:
                return UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.00)
            default:
                return UIColor.blue
            }
        }
    }

    private static var nostrilGradientSecondColor: UIColor {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.00)
            case .light:
                return UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1.00)
            default:
                return UIColor.blue
            }
        }
    }

    var noseColor: UIColor {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.28, green: 0.28, blue: 0.28, alpha: 1.00)
            case .light:
                return UIColor(red: 0.30, green: 0.30, blue: 0.30, alpha: 1.00)
            default:
                return UIColor.blue
            }
        }
    }

    var bridgeGradient: Gradient {
        return [GrayCatNose.noseBridgeGradientFirstColor.cgColor, GrayCatNose.noseBridgeGradientSecondColor.cgColor]
    }

    var nostrilGradient: Gradient {
        return [GrayCatNose.nostrilGradientFirstColor.cgColor, GrayCatNose.nostrilGradientSecondColor.cgColor]
    }
}

struct Colors {

    // Following property is used in case there will be more color themes in the future
    static let activeCatNoseColorScheme: CatNoseColorScheme = grayCatNose

    static let grayCatNose = GrayCatNose()

    static let background: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.00)
            case .light:
                return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.00)
            default:
                return UIColor.systemBackground
            }
        }
    }()

    static let backgroundSecondary: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.08, green: 0.07, blue: 0.07, alpha: 1.00)
            case .light:
                return UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.00)
            default:
                return UIColor.secondarySystemBackground
            }
        }
    }()

    static let backgroundTertiary: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.11, green: 0.10, blue: 0.10, alpha: 1.00)
            case .light:
                return UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.00)
            default:
                return UIColor.secondarySystemBackground
            }
        }
    }()

    static let naturalBackground: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.07, green: 0.06, blue: 0.06, alpha: 1.00)
            case .light:
                return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.00)
            default:
                return UIColor.systemBackground
            }
        }
    }()

    static let naturalSecondaryBackground: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.00)
            case .light:
                return UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.00)
            default:
                return UIColor.secondarySystemBackground
            }
        }
    }()

    static let popupBackground: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.12, green: 0.11, blue: 0.11, alpha: 1.00)
            case .light:
                return UIColor(red: 0.16, green: 0.15, blue: 0.15, alpha: 1.00)
            default:
                return UIColor.tertiarySystemBackground
            }
        }
    }()

    static let label: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.00)
            case .light:
                return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.00)
            default:
                return UIColor.label
            }
        }
    }()

    static let detailGray: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.00)
            case .light:
                return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.00)
            default:
                return UIColor.lightGray
            }
        }
    }()

    static let profilePicturePlaceholder: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.10, green: 0.09, blue: 0.09, alpha: 1.00)
            case .light:
                return UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1.00)
            default:
                return UIColor.secondarySystemBackground
            }
        }
    }()

    static let placeholder: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.13, green: 0.15, blue: 0.16, alpha: 1.00)
            case .light:
                return UIColor(red: 0.96, green: 0.96, blue: 0.95, alpha: 1.00)
            default:
                return UIColor.placeholderText
            }
        }
    }()

    static let green: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.00, green: 0.47, blue: 0.28, alpha: 1.00)
            case .light:
                return UIColor(red: 0.00, green: 0.62, blue: 0.38, alpha: 1.00)
            default:
                return UIColor.systemGreen
            }
        }
    }()

    static let heartRed: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.93, green: 0.11, blue: 0.20, alpha: 1.00)
            case .light:
                return UIColor(red: 0.94, green: 0.14, blue: 0.24, alpha: 1.00)
            default:
                return UIColor.systemRed
            }
        }
    }()

    static let bookmarked: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.00, green: 0.32, blue: 0.31, alpha: 1.00)
            case .light:
                return UIColor(red: 0.00, green: 0.42, blue: 0.40, alpha: 1.00)
            default:
                return UIColor.label
            }
        }
    }()

    static let unbookmarked: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.00)
            case .light:
                return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.00)
            default:
                return UIColor.systemBackground
            }
        }
    }()

    static let coolBlue: UIColor = {
        return UIColor.systemBlue
//        UIColor.init { traitCollection in
//            switch traitCollection.userInterfaceStyle {
//            case .dark:
//                return UIColor(red: 0.13, green: 0.15, blue: 0.16, alpha: 1.00)
//            case .light:
//                return UIColor(red: 0.96, green: 0.96, blue: 0.95, alpha: 1.00)
//            default:
//                return UIColor.systemBlue
//            }
//        }
    }()

    static let unseenBlue: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.13, green: 0.15, blue: 0.16, alpha: 1.00)
            case .light:
                return UIColor(red: 0.84, green: 0.94, blue: 0.97, alpha: 1.00)
            default:
                return UIColor.systemBlue
            }
        }
    }()

    static let progressBarTrackTint: UIColor = {
        UIColor.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.66, green: 0.84, blue: 1.00, alpha: 1.00)
            case .light:
                return UIColor(red: 0.66, green: 0.84, blue: 1.00, alpha: 1.00)
            default:
                return UIColor.systemBlue
            }
        }
    }()
}
