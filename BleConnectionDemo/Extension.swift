//
//  Extension.swift
//  whiteTiger
//
//  Created by Dongjie Zhang on 3/27/17.
//  Copyright © 2017 Zachary. All rights reserved.
//

import Foundation

//MARK: Data
extension Data {
    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}
