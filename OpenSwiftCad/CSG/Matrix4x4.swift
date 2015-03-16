//
//  Matrix4x4.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 14.03.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//

import Foundation

let π = M_PI

func sinCos(degrees: Double) -> (sin: Double, cos: Double) {
    let radians = degrees * π / 180.0
    return (sin: sin(radians), cos: cos(radians))
}

class Matrix4x4 {
    
    typealias Matrix4x4Elements =
        ((Double, Double, Double, Double),
         (Double, Double, Double, Double),
         (Double, Double, Double, Double),
         (Double, Double, Double, Double))
    
    let elements: Matrix4x4Elements
    
    init() {
        self.elements =
            ((1.0, 0.0, 0.0, 0.0),
             (0.0, 1.0, 0.0, 0.0),
             (0.0, 0.0, 1.0, 0.0),
             (0.0, 0.0, 0.0, 1.0))
    }
    
    init(elements: Matrix4x4Elements) {
        self.elements = elements
    }
    
    init?(elements: [Double]) {
        if elements.count != 16 {
            self.elements =
                ((1.0, 0.0, 0.0, 0.0),
                 (0.0, 1.0, 0.0, 0.0),
                 (0.0, 0.0, 1.0, 0.0),
                 (0.0, 0.0, 0.0, 1.0))
            return nil
        }
        self.elements =
            ((elements[0], elements[1], elements[2], elements[3]),
             (elements[4], elements[5], elements[6], elements[7]),
             (elements[8], elements[9], elements[10], elements[11]),
             (elements[12], elements[13], elements[14], elements[15]))
    }
    
    func multiply(matrix: Matrix4x4) -> Matrix4x4 {
        let s = self.elements
        let m = matrix.elements
        
        var result: [Double] = []
        result.append(s.0.0 * m.0.0 + s.1.0 * m.0.1 + s.2.0 * m.0.2 + s.3.0 * m.0.3)
        result.append(s.0.0 * m.1.0 + s.1.0 * m.1.1 + s.2.0 * m.1.2 + s.3.0 * m.1.3)
        result.append(s.0.0 * m.2.0 + s.1.0 * m.2.1 + s.2.0 * m.2.2 + s.3.0 * m.2.3)
        result.append(s.0.0 * m.3.0 + s.1.0 * m.3.1 + s.2.0 * m.3.2 + s.3.0 * m.3.3)

        result.append(s.0.1 * m.0.0 + s.1.1 * m.0.1 + s.2.1 * m.0.2 + s.3.1 * m.0.3)
        result.append(s.0.1 * m.1.0 + s.1.1 * m.1.1 + s.2.1 * m.1.2 + s.3.1 * m.1.3)
        result.append(s.0.1 * m.2.0 + s.1.1 * m.2.1 + s.2.1 * m.2.2 + s.3.1 * m.2.3)
        result.append(s.0.1 * m.3.0 + s.1.1 * m.3.1 + s.2.1 * m.3.2 + s.3.1 * m.3.3)
        
        result.append(s.0.2 * m.0.0 + s.1.2 * m.0.1 + s.2.2 * m.0.2 + s.3.2 * m.0.3)
        result.append(s.0.2 * m.1.0 + s.1.2 * m.1.1 + s.2.2 * m.1.2 + s.3.2 * m.1.3)
        result.append(s.0.2 * m.2.0 + s.1.2 * m.2.1 + s.2.2 * m.2.2 + s.3.2 * m.2.3)
        result.append(s.0.2 * m.3.0 + s.1.2 * m.3.1 + s.2.2 * m.3.2 + s.3.2 * m.3.3)
        
        result.append(s.0.3 * m.0.0 + s.1.3 * m.0.1 + s.2.3 * m.0.2 + s.3.3 * m.0.3)
        result.append(s.0.3 * m.1.0 + s.1.3 * m.1.1 + s.2.3 * m.1.2 + s.3.3 * m.1.3)
        result.append(s.0.3 * m.2.0 + s.1.3 * m.2.1 + s.2.3 * m.2.2 + s.3.3 * m.2.3)
        result.append(s.0.3 * m.3.0 + s.1.3 * m.3.1 + s.2.3 * m.3.2 + s.3.3 * m.3.3)
        
        return Matrix4x4(elements: result)!
    }
    
    func clone() -> Matrix4x4 {
        return Matrix4x4(elements: self.elements)
    }
    
    // Right multiply the matrix by a Vector3D (interpreted as 3 row, 1 column)
    // (result = M*v)
    // Fourth element is taken as 1
    func rightMultiply1x3Vector(v: Vector3D) -> Vector3D {
        let v0 = v.x
        let v1 = v.y
        let v2 = v.z
        let s = self.elements
        var x = v0 * s.0.0 + v1 * s.1.0 + v2 * s.2.0 + s.3.0
        var y = v0 * s.0.1 + v1 * s.1.1 + v2 * s.2.1 + s.3.1
        var z = v0 * s.0.2 + v1 * s.1.2 + v2 * s.2.2 + s.3.2
        var w = v0 * s.0.3 + v1 * s.1.3 + v2 * s.2.3 + s.3.3
        if (w != 1.0) {
            let invW = 1.0 / w
            x *= invW
            y *= invW
            z *= invW
        }
        return Vector3D(x: x, y: y, z: z)
    }
    
    // Multiply a Vector3D (interpreted as 3 column, 1 row) by this matrix
    // (result = v*M)
    // Fourth element is taken as 1
    func leftMultiply1x3Vector(v: Vector3D) -> Vector3D {
        let v0 = v.x
        let v1 = v.y
        let v2 = v.z
        let s = self.elements
        var x = v.x * s.0.0 + v.y * s.0.1 + v.z * s.0.2 + s.0.3
        var y = v.x * s.1.0 + v.y * s.1.1 + v.z * s.1.2 + s.1.3
        var z = v.x * s.2.0 + v.y * s.2.1 + v.z * s.2.2 + s.2.3
        var w = v.x * s.3.0 + v.y * s.3.1 + v.z * s.3.2 + s.3.3
        if (w != 1.0) {
            let invW = 1.0 / w
            x *= invW
            y *= invW
            z *= invW
        }
        return Vector3D(x: x, y: y, z: z)
    }
    
    // Right multiply the matrix by a Vector2D (interpreted as 2 row, 1 column)
    // (result = M*v)
    // Fourth element is taken as 1
    func rightMultiply1x2Vector(v: Vector2D) -> Vector2D {
        let v0 = v.x
        let v1 = v.y
        let s = self.elements
        var x = v0 * s.0.0 + v1 * s.1.0 + s.3.0
        var y = v0 * s.0.1 + v1 * s.1.1 + s.3.1
        var w = v0 * s.0.3 + v1 * s.1.3 + s.3.3
        if (w != 1.0) {
            let invW = 1.0 / w
            x *= invW
            y *= invW
        }
        return Vector2D(x: x, y: y)
    }
    
    // Multiply a Vector2D (interpreted as 2 column, 1 row) by this matrix
    // (result = v*M)
    // Fourth element is taken as 1
    func leftMultiply1x2Vector(v: Vector2D) -> Vector2D {
        let v0 = v.x
        let v1 = v.y
        let s = self.elements
        var x = v.x * s.0.0 + v.y * s.0.1 + s.0.3
        var y = v.x * s.1.0 + v.y * s.1.1 + s.1.3
        var w = v.x * s.3.0 + v.y * s.3.1 + s.3.3
        if (w != 1.0) {
            let invW = 1.0 / w
            x *= invW
            y *= invW
        }
        return Vector2D(x: x, y: y)
    }
    
	// determine whether this matrix is a mirroring transformation
    func isMirroring() -> Bool {
        let u = Vector3D(x: self.elements.0.0, y: self.elements.0.1, z: self.elements.0.2)
        let v = Vector3D(x: self.elements.1.0, y: self.elements.1.1, z: self.elements.1.2)
        let w = Vector3D(x: self.elements.2.0, y: self.elements.2.1, z: self.elements.2.2)

		// for a true orthogonal, non-mirrored base, u.cross(v) == w
		// If they have an opposite direction then we are mirroring
        let mirrorValue = u.cross(v).dot(w)
        return mirrorValue < 0.0
    }
    
    class func unity() -> Matrix4x4 {
        return Matrix4x4()
    }
    
    class func rotationX(degrees: Double) -> Matrix4x4 {
        let (sin, cos) = sinCos(degrees)
        return Matrix4x4(elements:
            ((1.0, 0.0, 0.0, 0.0),
             (0.0, cos, sin, 0.0),
             (0.0, -sin, cos, 0.0),
             (0.0, 0.0, 0.0, 1.0)))
    }
    
    class func rotationY(degrees: Double) -> Matrix4x4 {
        let (sin, cos) = sinCos(degrees)
        return Matrix4x4(elements:
            ((cos, 0.0, -sin, 0.0),
             (0.0, 1.0, 0.0, 0.0),
             (sin, 0.0, cos, 0.0),
             (0.0, 0.0, 0.0, 1.0)))
    }
    
    class func rotationZ(degrees: Double) -> Matrix4x4 {
        let (sin, cos) = sinCos(degrees)
        return Matrix4x4(elements:
            ((cos, sin, 0.0, 0.0),
             (-sin, cos, 0.0, 0.0),
             (0.0, 0.0, 1.0, 0.0),
             (0.0, 0.0, 0.0, 1.0)))
    }
    
    class func rotationFromCenter(center: Vector3D, aroundAxis axis: Vector3D, byDegrees degrees: Double) -> Matrix4x4 {
        let rotationPlane = Plane.fromNormal(axis, andPoint: center)
        let orthoBasis = OrthoNormalBasis(plane: rotationPlane)
        var transformation = Matrix4x4.translation(center.negated())
        transformation = transformation.multiply(orthoBasis.projectionMatrix())
        transformation = transformation.multiply(Matrix4x4.rotationZ(degrees))
        transformation = transformation.multiply(orthoBasis.inverseProjectionMatrix())
        return transformation.multiply(Matrix4x4.translation(center))
    }
    
    class func translation(vector: Vector3D) -> Matrix4x4 {
        return Matrix4x4(elements:
            ((1.0, 0.0, 0.0, 0.0),
             (0.0, 1.0, 0.0, 0.0),
             (0.0, 0.0, 1.0, 0.0),
             (vector.x, vector.y, vector.z, 1.0)))
    }
    
    class func mirroring(plane: Plane) -> Matrix4x4 {
        let nx = plane.normal.x
        let ny = plane.normal.y
        let nz = plane.normal.z
        let w = plane.w
        return Matrix4x4(elements:
            ((1.0 - 2.0 * nx * nx, -2.0 * ny * nx, -2.0 * nz * nx, 0.0),
             (-2.0 * nx * ny, 1.0 - 2.0 * ny * ny, -2.0 * nz * ny, 0.0),
             (-2.0 * nx * nz, -2.0 * ny * nz, 1.0 - 2.0 * nz * nz, 0.0),
             (-2.0 * nx * w, -2.0 * ny * w, -2.0 * nz * w, 1.0)))
    }
    
    class func scaling(vector: Vector3D) -> Matrix4x4 {
        return Matrix4x4(elements:
            ((vector.x, 0.0, 0.0, 0.0),
             (0.0, vector.y, 0.0, 0.0),
             (0.0, 0.0, vector.z, 0.0),
             (0.0, 0.0, 0.0, 1.0)))
    }
    
}