//
//  UIRefreshControl.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 09.01.2024.
//

import UIKit.UIRefreshControl

extension UIRefreshControl {

    func beginRefreshingManually() {
        if let scrollView = superview as? UIScrollView {
            scrollView.setContentOffset(CGPoint(x: 0, y: 0 - frame.height), animated: false)
        }
        beginRefreshing()
        sendActions(for: .valueChanged)
    }
}
