//
//  OrthoNormalBasis.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 15.03.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//
// Reprojects points on a 3D plane onto a 2D plane
// or from a 2D plane back onto the 3D plane

import Foundation

class OrthoNormalBasis {
    
    let v: Vector3D
    let u: Vector3D
    let plane: Plane
    let planeOrigin: Vector3D
    
    init(plane: Plane, rightVector: Vector3D) {
        self.plane = plane
        self.planeOrigin = plane.normal.times(plane.w)
        self.v = plane.normal.cross(rightVector).unit()
        self.u = self.v.cross(plane.normal)
    }
    
    convenience init(plane: Plane) {
        self.init(plane: plane, rightVector: plane.normal.randomNonParallelVector())
    }
    
    class func Z0Plane() -> OrthoNormalBasis {
        let plane = Plane(normal: Vector3D(x: 0.0, y: 0.0, z: 1.0), w: 0.0)
        return OrthoNormalBasis(plane: plane, rightVector: Vector3D(x: 1.0, y: 0.0))
    }
    
    func projectionMatrix() -> Matrix4x4 {
        return Matrix4x4(elements:
            ((self.u.x, self.v.x, self.plane.normal.x, 0.0),
             (self.u.y, self.v.y, self.plane.normal.y, 0.0),
             (self.u.z, self.v.z, self.plane.normal.z, 0.0),
             (0.0, 0.0, -self.plane.w, 1.0)))
    }
    
    func inverseProjectionMatrix() -> Matrix4x4 {
        let p = self.plane.normal.times(self.plane.w)
        return Matrix4x4(elements:
            ((self.u.x, self.u.y, self.u.z, 0.0),
             (self.v.x, self.v.y, self.v.z, 0.0),
             (self.plane.normal.x, self.plane.normal.y, self.plane.normal.z, 0.0),
             (p.x, p.y, p.z, 1.0)))
    }
    
    func to2D(vector: Vector3D) -> Vector2D {
        return Vector2D(x: vector.dot(self.u), y: vector.dot(self.v))
    }
    
    func to3D(vector: Vector2D) -> Vector3D {
        return self.planeOrigin.plus(self.u.times(vector.x)).plus(self.v.times(vector.y))
    }
    
    func line3Dto2D(line: Line3D) -> Line2D {
        let a = line.point
        let b = line.direction.plus(a)
        return Line2D.fromPoints(self.to2D(a), self.to2D(b))
    }
    
    func line2Dto3D(line: Line2D) -> Line3D {
        let a = line.origin()
        let b = line.direction().plus(a)
        return Line3D.fromPoints(self.to3D(a), self.to3D(b))
    }
    
    func transform(matrix: Matrix4x4) -> OrthoNormalBasis {
        // todo: this may not work properly in case of mirroring
        let newPlane = self.plane.transform(matrix)
        let transformedRightPoint = self.u.multiply4x4(matrix)
        let transformedOrigin = Vector3D(val: 0.0).multiply4x4(matrix)
        let newRightHandVector = transformedRightPoint.minus(transformedOrigin)
        return OrthoNormalBasis(plane: newPlane, rightVector: newRightHandVector);
    }
}