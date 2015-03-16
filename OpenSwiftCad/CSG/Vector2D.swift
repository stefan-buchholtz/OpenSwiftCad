//
//  Vector2D.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 14.03.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//

import Foundation

func vector2DfromAngleDegrees(degrees: Double) -> Vector2D {
    return vector2DfromAngleRadians(degrees * π / 180.0)
}

func vector2DfromAngleRadians(radians: Double) -> Vector2D {
    return Vector2D(x: cos(radians), y: sin(radians))
}

struct Vector2D {
    
    let x, y: Double
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init(val: Double) {
        self.x = val
        self.y = val
    }
    
    init(vector: Vector3D) {
        self.x = vector.x
        self.y = vector.y
    }
    
    init(vector: Vector2D) {
        self.x = vector.x
        self.y = vector.y
    }
    
    init(vector: (Double, Double)) {
        self.x = vector.0
        self.y = vector.1
    }
    
    init?(elems: [Double]) {
        if (elems.count != 2) {
            self.x = 0.0
            self.y = 0.0
            return nil
        }
        self.x = elems[0]
        self.y = elems[1]
    }
    
    func toVector3D(z: Double) -> Vector3D {
        return Vector3D(x: self.x, y: self.y, z: z)
    }
    
    func equals(a: Vector2D) -> Bool {
        return self.x == a.x && self.y == a.y
    }

    func negated() -> Vector2D {
        return Vector2D(x: -self.x, y: -self.y)
    }
    
    func plus(a: Vector2D) -> Vector2D {
        return Vector2D(x: self.x + a.x, y: self.y + a.y)
    }
    
    func minus(a: Vector2D) -> Vector2D {
        return Vector2D(x: self.x - a.x, y: self.y - a.y)
    }

    func times(a: Double) -> Vector2D {
        return Vector2D(x: self.x * a, y: self.y * a)
    }
    
    func dividedBy(a: Double) -> Vector2D {
        return Vector2D(x: self.x / a, y: self.y / a)
    }
    
    func dot(a: Vector2D) -> Double {
        return self.x * a.x + self.y * a.y
    }
    
    func lerp(a: Vector2D, _ t: Double) -> Vector2D {
        return self.plus(a.minus(self).times(t))
    }
    
    func lengthSquared() -> Double {
        return self.dot(self)
    }
    
    func length() -> Double {
        return sqrt(self.lengthSquared())
    }
    
    func distanceTo(a: Vector2D) -> Double {
        return self.minus(a).length()
    }
    
    func distanceToSquared(a: Vector2D) -> Double {
        return self.minus(a).lengthSquared()
    }
    
    func unit() -> Vector2D {
        return self.dividedBy(self.length())
    }
    
    func cross(a: Vector2D) -> Double {
        return self.x * a.y - self.y * a.x
    }
    
    func normal() -> Vector2D {
        return Vector2D(x: self.y, y: -self.x)
    }
    
    func multiply4x4(matrix: Matrix4x4) -> Vector2D {
        return matrix.leftMultiply1x2Vector(self)
    }
    
    func angle() -> Double {
        return self.angleRadians()
    }
    
    func angleRadians() -> Double {
        return atan2(self.y, self.x)
    }
    
    func angleDegrees() -> Double {
        return 180.0 * self.angleRadians() / π
    }
    
    func min(a: Vector2D) -> Vector2D {
        return Vector2D(x: fmin(self.x, a.x), y: fmin(self.y, a.y))
    }
    
    func max(a: Vector2D) -> Vector2D {
        return Vector2D(x: fmax(self.x, a.x), y: fmax(self.y, a.y))
    }
    
    func stringValue() -> String {
        return NSString(format: "(%.2f, %.2f)", self.x, self.y)
    }
    
    func description() -> String {
        return self.stringValue()
    }

}