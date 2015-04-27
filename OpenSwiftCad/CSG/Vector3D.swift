//
//  Vector3D.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 14.03.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//

import Foundation

struct Vector3D {
    
    let x, y, z: Double
    
    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
        self.z = 0.0
    }
    
    init(val: Double) {
        self.x = val
        self.y = val
        self.z = val
    }
    
    init(vector: Vector3D) {
        self.x = vector.x
        self.y = vector.y
        self.z = vector.z
    }
    
    init(vector: Vector2D) {
        self.x = vector.x
        self.y = vector.y
        self.z = 0.0
    }
    
    init(vector: (Double, Double, Double)) {
        self.x = vector.0
        self.y = vector.1
        self.z = vector.2
    }
    
    init?(elems: [Double]) {
        if (elems.count < 2 || elems.count > 3) {
            self.x = 0.0
            self.y = 0.0
            self.z = 0.0
            return nil
        }
        self.x = elems[0]
        self.y = elems[1]
        if elems.count == 3 {
            self.z = elems[2]
        } else {
            self.z = 0.0
        }
    }
    
    func negated() -> Vector3D {
        return Vector3D(x: -self.x, y: -self.y, z: -self.z)
    }
    
    func abs() -> Vector3D {
        return Vector3D(x: fabs(self.x), y: fabs(self.y), z: fabs(self.z))
    }
    
    func plus(a: Vector3D) -> Vector3D {
        return Vector3D(x: self.x + a.x, y: self.y + a.y, z: self.z + a.z)
    }
    
    func minus(a: Vector3D) -> Vector3D {
        return Vector3D(x: self.x - a.x, y: self.y - a.y, z: self.z - a.z)
    }
    
    func times(a: Double) -> Vector3D {
        return Vector3D(x: self.x * a, y: self.y * a, z: self.z * a)
    }
    
    func dividedBy(a: Double) -> Vector3D {
        return Vector3D(x: self.x / a, y: self.y / a, z: self.z / a)
    }
    
    func dot(a: Vector3D) -> Double {
        return self.x * a.x + self.y * a.y + self.z * a.z
    }
    
    func lerp(a: Vector3D, _ t: Double) -> Vector3D {
        return self.plus(a.minus(self).times(t))
    }
    
    func lengthSquared() -> Double {
        return self.dot(self)
    }
    
    func length() -> Double {
        return sqrt(self.lengthSquared())
    }
    
    func unit() -> Vector3D {
        return self.dividedBy(self.length())
    }
    
    func cross(a: Vector3D) -> Vector3D {
        return Vector3D(x: self.y * a.z - self.z * a.y, y: self.z * a.x - self.x * a.z, z: self.x * a.y - self.y * a.x)
    }
    
    func distanceTo(a: Vector3D) -> Double {
        return self.minus(a).length()
    }
    
    func distanceToSquared(a: Vector3D) -> Double {
        return self.minus(a).lengthSquared()
    }
    
    func equals(a: Vector3D) -> Bool {
        return self.x == a.x && self.y == a.y && self.z == a.z
    }
    
    func multiply4x4(matrix: Matrix4x4) -> Vector3D {
        return matrix.leftMultiply1x3Vector(self)
    }
    
    /*
    func transform(matrix: Matrix4x4) -> Vector3D {
        return matrix.leftMultiply1x3Vector(self)
    }
    */
    
    func stlStringValue() -> String {
        return "\(self.x) \(self.y) \(self.z)"
    }
    
    func amfStringValue() -> String {
        return "<x>\(self.x)</x><y>\(self.y)</y><z>\(self.z)</z>"
    }
    
    func stringValue() -> String {
        return NSString(format: "(%.2f, %.2f, %.2f)", self.x, self.y, self.z) as String
    }
    
    func description() -> String {
        return self.stringValue()
    }
    
    // find a vector that is somewhat perpendicular to this one
    func randomNonParallelVector() -> Vector3D {
        let abs = self.abs()
        if (abs.x <= abs.y) && (abs.x <= abs.z) {
            return Vector3D(x: 1.0, y: 0.0, z: 0.0)
        } else if (abs.y <= abs.x) && (abs.y <= abs.z) {
            return Vector3D(x: 0.0, y: 1.0, z: 0.0)
        } else {
            return Vector3D(x: 0.0, y: 0.0, z: 1.0)
        }
    }
    
    func min(a: Vector3D) -> Vector3D {
        return Vector3D(x: fmin(self.x, a.x), y: fmin(self.y, a.y), z: fmin(self.z, a.z))
    }
    
    func max(a: Vector3D) -> Vector3D {
        return Vector3D(x: fmax(self.x, a.x), y: fmax(self.y, a.y), z: fmax(self.z, a.z))
    }
    
}