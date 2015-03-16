//
//  Line3D.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 14.03.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//
// Represents a line in 3D space
// direction must be a unit vector
// point is a random point on the line

import Foundation

class Line3D {
    
    let point: Vector3D
    let direction: Vector3D
    
    init(point: Vector3D, direction: Vector3D) {
        self.point = point
        self.direction = direction.unit()
    }
    
    class func fromPoints(p1: Vector3D, _ p2: Vector3D) -> Line3D {
        return Line3D(point: p1, direction: p2.minus(p1))
    }
    
    class func intersectionOfPlanes(p1: Plane, _ p2: Plane) -> Line3D? {
        var direction = p1.normal.cross(p2.normal)
        let len = direction.length()
        if len < 1e-10 {
            println("Parallel planes")
            return nil
        }
        direction = direction.times(1.0 / len)
        let mabsx = fabs(direction.x)
        let mabsy = fabs(direction.y)
        let mabsz = fabs(direction.z)
        var origin: Vector3D
        if mabsx >= mabsy && mabsx >= mabsz {
            // direction vector is mostly pointing towards x
            // find a point p for which x is zero:
            let r = CSG.solve2Linear(p1.normal.y, p1.normal.z, p2.normal.y, p2.normal.z, p1.w, p2.w)
            origin = Vector3D(x: 0.0, y: r.0, z: r.1)
        } else if mabsy >= mabsx && mabsy >= mabsz {
            let r = CSG.solve2Linear(p1.normal.x, p1.normal.z, p2.normal.x, p2.normal.z, p1.w, p2.w)
            origin = Vector3D(x: r.0, y: 0.0, z: r.1)
        } else {
            let r = CSG.solve2Linear(p1.normal.x, p1.normal.y, p2.normal.x, p2.normal.y, p1.w, p2.w)
            origin = Vector3D(x: r.0, y: r.1, z: 0.0)
        }
        return Line3D(point: origin, direction: direction)
    }
    
    func intersectWithPlane(plane: Plane) -> Vector3D {
        // plane: plane.normal * p = plane.w
        // line: p=line.point + labda * line.direction
        let labda = (plane.w - plane.normal.dot(self.point)) / plane.normal.dot(self.direction)
        return self.point.plus(self.direction.times(labda))
    }
    
    func clone() -> Line3D {
        return Line3D(point: self.point, direction: self.direction)
    }
    
    func equals(a: Line3D) -> Bool {
        if !self.direction.equals(a.direction) {
            return false
        }
        let distance = self.distanceToPoint(a.point)
        return distance < 1e-8
    }
    
    func reverse() -> Line3D {
        return Line3D(point: self.point, direction: direction.negated())
    }
    
    func transform(matrix: Matrix4x4) -> Line3D {
        let newPoint = self.point.multiply4x4(matrix)
        let pointPlusDirection = self.point.plus(self.direction)
        let newPointPlusDirection = pointPlusDirection.multiply4x4(matrix)
        let newDirection = newPointPlusDirection.minus(newPoint)
        return Line3D(point: newPoint, direction: newDirection)
    }
    
    func closestPointOnLine(point: Vector3D) -> Vector3D {
        let t = point.minus(self.point).dot(self.direction) / self.direction.dot(self.direction)
        return self.point.plus(self.direction.times(t))
    }
    
    func distanceToPoint(point: Vector3D) -> Double {
        let closestPoint = self.closestPointOnLine(point)
        return point.minus(closestPoint).length()
    }
}