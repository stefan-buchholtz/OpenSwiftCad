//
//  Vertex2D.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 15.03.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//

import Foundation

class Vertex2D {
    
    let pos: Vector2D
    private var tag = 0
    
    init(pos: Vector2D) {
        self.pos = pos
    }
    
    func getTag() -> Int {
        if self.tag == 0 {
            self.tag = CSG.getTag()
        }
        return self.tag
    }
    
    func stringValue() -> String {
        return pos.stringValue()
    }
    
    func description() -> String {
        return self.stringValue()
    }
    
}