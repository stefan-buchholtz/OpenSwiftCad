//
//  Line2D.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 15.03.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//
// Represents a directional line in 2D space
// A line is parametrized by its normal vector (perpendicular to the line, rotated 90 degrees counter clockwise)
// and w. The line passes through the point <normal>.times(w).
// normal must be a unit vector!
// Equation: p is on line if normal.dot(p)==w

import Foundation

class Line2D {
    
    let normal: Vector2D
    let w: Double
    
    init(normal: Vector2D, w: Double) {
        let len = normal.length()
        
        // normalize
        self.normal = normal.dividedBy(len)
        self.w = w * len
    }
    
    class func fromPoints(p1: Vector2D, _ p2: Vector2D) -> Line2D {
        let direction = p2.minus(p1)
        let normal = direction.normal().negated().unit()
        let w = p1.dot(normal)
        return Line2D(normal: normal, w: w)
    }
    
    // same line but opposite direction
    func reverse() -> Line2D {
        return Line2D(normal: self.normal.negated(), w: -self.w)
    }
    
    func equals(a: Line2D) -> Bool {
        return a.normal.equals(self.normal) && a.w == self.w
    }
    
    func origin() -> Vector2D {
        return self.normal.times(self.w)
    }
    
    func direction() -> Vector2D {
        return self.normal.normal()
    }
    
    func xAtY(y: Double) -> Double {
        // (py == y) && (normal * p == w)
        // -> px = (w - normal._y * y) / normal.x
        return (self.w - self.normal.y * y) / self.normal.x
    }
    
    func absDistanceToPoint(point: Vector2D) -> Double {
        let projectedPoint = point.dot(self.normal)
        return fabs(projectedPoint - self.w)
    }
    
    func intersectWithLine(line: Line2D) -> Vector2D {
        return Vector2D(vector: CSG.solve2Linear(self.normal.x, self.normal.y, line.normal.x, line.normal.y, self.w, line.w))
    }
    
    func transform(matrix: Matrix4x4) -> Line2D {
        let origin = Vector2D(x: 0.0, y: 0.0)
        let pointOnPlane = self.normal.times(self.w)
        let newOrigin = origin.multiply4x4(matrix)
        let newOriginPlusNormal = self.normal.multiply4x4(matrix)
        let newNormal = newOriginPlusNormal.minus(newOrigin)
        let newPointOnPlane = pointOnPlane.multiply4x4(matrix)
        let newW = newNormal.dot(newPointOnPlane)
        return Line2D(normal: newNormal, w: newW)
    }
}