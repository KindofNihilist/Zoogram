//
//  String.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 22.12.2023.
//

import Foundation

extension String {
    func trimmingExtraWhitespace() -> String {
        return self.replacingOccurrences(of: "(?<=\\s)\\s+|\\s+(?=$)|(?<=^)\\s+",
                                         with: "",
                                         options: .regularExpression)
    }
}
