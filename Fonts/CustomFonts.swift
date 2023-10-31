//
//  CustomFonts.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.10.2023.
//

import UIKit

class CustomFonts {

    static func logoFont(ofSize size: CGFloat) -> UIFont? {
        return UIFont(name: "Katto-PersonalUse-Outline", size: size)
    }

    static func boldFont(ofSize size: CGFloat) -> UIFont? {
//        return UIFont(name: "Comfortaa-Bold", size: size)
//        return UIFont(name: "WixMadeforDisplay-Bold", size: size)
//        return UIFont(name: "RoundedMplus1c-Bold", size: size)
        return UIFont(name: "TTRounds-Bold", size: size)
//        return UIFont.systemFont(ofSize: size, weight: .bold)
    }

    static func regularFont(ofSize size: CGFloat) -> UIFont? {
//        return UIFont(name: "Comfortaa-Regular", size: size)
//        return UIFont(name: "WixMadeforDisplay-Regular", size: size)
//        return UIFont(name: "RoundedMplus1c-Regular", size: size)
        return UIFont(name: "TTRounds-Regular", size: size)
//        return UIFont.systemFont(ofSize: size, weight: .regular)
    }

    static func lightFont(ofSize size: CGFloat) -> UIFont? {
//        return UIFont(name: "Comfortaa-Light", size: size)
//        return UIFont(name: "WixMadeforDisplay-Bold", size: size)
//        return UIFont(name: "RoundedMplus1c-Light", size: size)
        return UIFont(name: "TTRounds-Light", size: size)
//        return UIFont.systemFont(ofSize: size, weight: .light)
    }
}
