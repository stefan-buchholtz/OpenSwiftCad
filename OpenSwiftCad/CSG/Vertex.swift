//
//  Vertex.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 14.03.15.
//
//

import Foundation

class Vertex {
    
    let pos: Vector3D
    private var tag = 0
    
    init(pos: Vector3D ) {
        self.pos = pos;
    }
    
    func flipped() -> Vertex {
        return self
    }
    
    func getTag() -> Int {
        if self.tag == 0 {
            self.tag = CSG.getTag()
        }
        return self.tag
    }
    
    func interpolate(other: Vertex, fraction: Double) -> Vertex {
        let newPos = self.pos.lerp(other.pos, fraction)
        return Vertex(pos: newPos)
    }
    
    func transform(matrix: Matrix4x4) -> Vertex {
        let newPos = self.pos.multiply4x4(matrix)
        return Vertex(pos: newPos)
    }
    
    func stlStringValue() -> String {
        return "vertex \(self.pos.stlStringValue())\n"
    }
    
    func amfStringValue() -> String {
        return "<vertex><coordinates>\(self.pos.amfStringValue())</coordinates></vertex>"
    }
    
    func stringValue() -> String {
        return pos.stringValue()
    }
    
    func description() -> String {
        return self.stringValue()
    }
    
}