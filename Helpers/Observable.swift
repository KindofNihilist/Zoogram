//
//  Observable.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.11.2022.
//

import Foundation

class Observable<T> {
    var value: T {
        didSet {
          listener?(value)
        }
    }

    init(_ value: T) {
        self.value = value
    }

    private var listener: ((T) -> Void)?

    func bind(_ listener: @escaping (T) -> Void) {
        listener(value)
        self.listener = listener
    }
}
