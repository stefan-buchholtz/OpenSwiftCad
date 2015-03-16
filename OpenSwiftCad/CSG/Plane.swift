//
//  Plane.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 14.03.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//

import Foundation

var _PLANE_EPSILON = 1e-5

class Plane {
    
    let normal: Vector3D
    let w: Double
    private var tag: Int = 0
    
    init(normal: Vector3D, w: Double) {
        self.normal = normal
        self.w = w
    }
    
    class var EPSILON: Double {
        get {
            return _PLANE_EPSILON
        }
        set {
            _PLANE_EPSILON = newValue
        }
    }
    
    class func fromPoints(a: Vector3D, _ b: Vector3D, _ c: Vector3D) -> Plane {
        let n = b.minus(a).cross(c.minus(a)).unit()
        return Plane(normal: n, w: n.dot(a))
    }
    
    class func anyPlaneFromVector3Ds(a: Vector3D, _ b: Vector3D, _ c: Vector3D) -> Plane {
        var v1 = b.minus(a)
        var v2 = c.minus(a)
        if v1.length() < _PLANE_EPSILON {
            v1 = v2.randomNonParallelVector()
        }
        if v2.length() < _PLANE_EPSILON {
            v2 = v1.randomNonParallelVector()
        }
        var normal = v1.cross(v2)
        if normal.length() < _PLANE_EPSILON {
            v2 = v1.randomNonParallelVector()
            normal = v1.cross(v2)
        }
        normal = normal.unit()
        return Plane(normal: normal, w: normal.dot(a))
    }
    
    class func fromNormal(normal: Vector3D, andPoint point: Vector3D) -> Plane {
        let n = normal.unit()
        let w = point.dot(normal)
        return Plane(normal: n, w: w)
    }
    
    func flipped() -> Plane {
        return Plane(normal: self.normal.negated(), w: -self.w)
    }
    
    func getTag() -> Int {
        if self.tag == 0 {
            self.tag = CSG.getTag()
        }
        return self.tag
    }
    
    func equals(p: Plane) -> Bool {
        return self.normal.equals(p.normal) && self.w == p.w
    }
    
    func transform(matrix: Matrix4x4) -> Plane {
        let isMirror = matrix.isMirroring()
        
        // get two vectors in the plane:
        let r = self.normal.randomNonParallelVector()
        let u = self.normal.cross(r)
        let v = self.normal.cross(u)
        
        // get 3 points in the plane:
        var point1 = self.normal.times(self.w)
        var point2 = point1.plus(u)
        var point3 = point1.plus(v)
        
        // transform the points:
        point1 = point1.multiply4x4(matrix)
        point2 = point2.multiply4x4(matrix)
        point3 = point3.multiply4x4(matrix)
        
        // and create a new plane from the transformed points:
        let newPlane = Plane.fromPoints(point1, point2, point3)
        if isMirror {
            // the transform is mirroring
            // We should mirror the plane:
            return newPlane.flipped()
        } else {
            return newPlane;
        }
    }
    
    enum SplitPolygonResult {
        case CoPlanarFront()
        case CoPlanarBack()
        case Front()
        case Back()
        case Spanning(front: Polygon?, back: Polygon?)
    }
    
    func splitPolygon(polygon: Polygon) -> SplitPolygonResult {
        if polygon.plane.equals(self) {
            return SplitPolygonResult.CoPlanarFront()
        } else {
            let EPS = Plane.EPSILON
            let MINEPS = -Plane.EPSILON
            let vertices = polygon.vertices
            var hasFront = false
            var hasBack = false
            var vertexIsBack = [Bool] = []
            for vertex in vertices {
                let t = self.normal.dot(vertex.pos) - this.w
                let isBack = (t < 0.0)
                vertexIsBack.append(isBack)
                if t > EPS {
                    hasFront = true
                } else if t < MINEPS {
                    hasBack = true
                }
            }
            if !hasFront && !hasBack {
                // all points coplanar
                let t = plane.normal.dot(polygon.plane.normal)
                return t >= 0.0 ? SplitPolygonResult.CoPlanarFront() : SplitPolygonResult.CoPlanarBack()
            } else if !hasBack {
                return SplitPolygonResult.Front()
            } else if !hasFront {
                return SplitPolygonResult.Back()
            } else {
                // spanning
                var frontVertices: [Vertex] = []
                var backVertices: [Vertex] = []
                var isBack = vertexIsBack[0]
                for idx in 0..<vertices.count {
                    let vertex = vertices[idx]
                    var nextIdx = idx + 1
                    if nextIdx >= vertices.count {
                        nextIdx = 0
                    }
                    let nextIsBack = vertexIsBack[nextIdx]
                    if isBack == nextIsBack {
                        // line segment is on one side of the plane
                        if isBack {
                            backVertices.append(vertex)
                        } else {
                            frontVertices.append(vertex)
                        }
                    } else {
                        // line segment intersects plane
                        let point = vertex.pos
                        let nextPoint = vertices[nextIdx].pos
                        let intersectionPoint = self.splitLineBetweenPoints(point1: point, point2: nextPoint)
                        let intersectionVertex = Vertex(pos: intersectionPoint)
                        if isBack {
                            backVertices.append(vertex)
                            backVertices.append(intersectionVertex)
                            frontVertices.append(intersectionVertex)
                        } else {
                            frontVertices.append(vertex)
                            frontvertices.append(intersectionVertex)
                            backVertices.append(intersectionVertex)
                        }
                    }
                    isBack = nextIsBack
                } // for idx
                
                // remove duplicate vertices
                frontVertices = self.removeDuplicatePoints(frontVertices)
                backVertices = self.removeDuplicatePoints(backVertices)
                let front: Polygon? = frontVertices.count >= 3 ? Polygon(frontVertices, polygon.shared, polygon.plane) : nil
                let back: Polygon? = backVertices.count >= 3 ? Polygon(backVertices, polygon.shared, polygon.plane) : nil
                return SplitPolygonResult.Spanning(front: front, back: back)
            }
        }
    }
    
    func removeDuplicatePoints(vertices: [Vertex]) -> [Vertex] {
        if vertices.count >= 3 {
            var result: [Vertex] = []
            let EPS_SQUARED = Plane.EPSILON * Plane.EPSILON
            var prevVertex = vertices.last!
            for vertex in vertices {
                if vertex.pos.distanceToSquared(prevVertex.pos) >= EPS_SQUARED {
                    result.append(vertex)
                }
                prevVertex = vertex
            }
            return result
        } else {
            return vertices
        }
    }
    
    // robust splitting of a line by a plane
    // will work even if the line is parallel to the plane
    func splitLineBetweenPoints(point1: Vector3D, point2: Vector3D) -> Vector3D {
        let direction = point2.minus(point1)
        var labda = (self.w - self.normal.dot(point1)) / self.normal.dot(direction)
        if isnan(labda) {
            labda = 0.0
        } else if labda > 1.0 {
            labda = 1.0
        } else if labda < 0.0 {
            labda = 0.0
        }
        return point1.plus(direction.times(labda))
    }
    
    func intersectWithLine(line: Line3D) -> Vector3D {
        return line.intersectWithPlane(self)
    }
    
    func intersectWithPlane(plane: Plane) -> Line3D? {
        return Line3D.intersectionOfPlanes(self, plane)
    }
    
    func signedDistanceToPoint(point: Vector3D) -> Double {
        return self.normal.dot(point) - self.w
    }
    
    func mirrorPoint(point: Vector3D) -> Vector3D {
        let distance = signedDistanceToPoint(point)
        return point.minus(self.normal.times(distance * 2.0))
    }
    
    func stringValue() -> String {
        return "[normal: \(self.normal), w: \(self.w)]"
    }
    
    func description() -> String {
        return self.stringValue()
    }
    
}