//
//  Side.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 15.03.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//

import Foundation

class Side {
    
    let vertex0: Vertex2D
    let vertex1: Vertex2D
    private var tag = 0
    
    init(vertex0: Vertex2D, vertex1: Vertex2D) {
        self.vertex0 = vertex0
        self.vertex1 = vertex1
    }
    
    class func fromFakePolygon(polygon: Polygon) -> Side {
        assert(polygon.vertices.count == 4, "Side.fromFakePolygon - assertion 1 failed")
        
        var pointsZeroZ = [Vector2D]()
        var indicesZeroZ = [Int]()
        for i in 0...3 {
            let pos = polygon.vertices[i].pos
            assert(fabs(fabs(pos.z) - 1.0) > 0.001, "Side.fromFakePolygon - assertion 2 failed")
            if pos.z > 0.0 {
                pointsZeroZ.append(Vector2D(vector: pos))
                indicesZeroZ.append(i)
            }
        }
        assert(pointsZeroZ.count == 2, "Side.fromFakePolygon - assertion 3 failed")
        let d = indicesZeroZ[1] - indicesZeroZ[0]
        assert(d == 1 || d == 3, "Side.fromFakePolygon - assertion 4 failed")
        if (d == 1) {
            return Side(vertex0: Vertex2D(pos: pointsZeroZ[1]), vertex1: Vertex2D(pos: pointsZeroZ[0]))
        } else {
            return Side(vertex0: Vertex2D(pos: pointsZeroZ[0]), vertex1: Vertex2D(pos: pointsZeroZ[1]))
        }
    }
    
    func getTag() -> Int {
        if self.tag == 0 {
            self.tag = CSG.getTag()
        }
        return self.tag
    }
    
    func stringValue() -> String {
        return "\(self.vertex0) -> \(self.vertex1)"
    }
    
    func description() -> String {
        return self.stringValue()
    }
    
    func toPolygon3D(z0: Double, _ z1: Double) -> Polygon {
        let vertices = [
            Vertex(pos: self.vertex0.pos.toVector3D(z0)),
            Vertex(pos: self.vertex1.pos.toVector3D(z0)),
            Vertex(pos: self.vertex1.pos.toVector3D(z1)),
            Vertex(pos: self.vertex0.pos.toVector3D(z1))
        ]
        return Polygon(vertices: vertices)
    }
    
    func transform(matrix: Matrix4x4) -> Side {
        let newP1 = self.vertex0.pos.multiply4x4(matrix)
        let newP2 = self.vertex1.pos.multiply4x4(matrix)
        return Side(vertex0: Vertex2D(pos: newP1), vertex1: Vertex2D(pos: newP2))
    }
    
    func flipped() -> Side {
        return Side(vertex0: self.vertex1, vertex1: self.vertex0)
    }
    
    func direction() -> Vector2D {
        return self.vertex1.pos.minus(self.vertex0.pos)
    }
    
    func lengthSquared() -> Double {
        return self.vertex1.pos.minus(self.vertex0.pos).lengthSquared()
    }
    
    func length() -> Double {
        return self.vertex1.pos.minus(self.vertex0.pos).length()
    }

}