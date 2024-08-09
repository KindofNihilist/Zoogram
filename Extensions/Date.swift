//
//  Date.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.11.2023.
//

import Foundation

extension Date {
    func timeAgoDisplay() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))

        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        let month = 4 * week

        let quotient: Int
        if secondsAgo < minute {
            quotient = secondsAgo
            return String(localized: "\(quotient) second ago")
        } else if secondsAgo < hour {
            quotient = secondsAgo / minute
            return String(localized: "\(quotient) min ago")
        } else if secondsAgo < day {
            quotient = secondsAgo / hour
            return String(localized: "\(quotient) hour ago")
        } else if secondsAgo < week {
            quotient = secondsAgo / day
            return String(localized: "\(quotient) day ago")
        } else if secondsAgo < month {
            quotient = secondsAgo / week
            return String(localized: "\(quotient) week ago")
        } else {
            quotient = secondsAgo / month
            return String(localized: "\(quotient) month ago")
        }
    }
}
