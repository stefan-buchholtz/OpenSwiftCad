//
//  utils.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 16.03.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//

import Foundation

extension Array {
    
    func reduce1<U>(initer: T -> U, combine: (U, T) -> U) -> U? {
        if self.isEmpty {
            return nil
        }
        let initial = initer(self[0])
        return self[1..<self.count].reduce(initial, combine: combine)
    }

    func reduce1(combine: (T, T) -> T) -> T? {
        if self.isEmpty {
            return nil
        }
        return self[1..<self.count].reduce(self[0], combine: combine)
    }
    
}

