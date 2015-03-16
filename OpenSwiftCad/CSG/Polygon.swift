//
//  Polygon.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 14.03.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//
// Represents a convex polygon. The vertices used to initialize a polygon must
// be coplanar and form a convex loop. They do not have to be `CSG.Vertex`
// instances but they must behave similarly (duck typing can be used for
// customization).
//
// Each convex polygon has a `shared` property, which is shared between all
// polygons that are clones of each other or were split from the same polygon.
// This can be used to define per-polygon properties (such as surface color).
//
// The plane of the polygon is calculated from the vertex coordinates
// To avoid unnecessary recalculation, the plane can alternatively be
// passed as the third argument

import Foundation

typealias Color = (red: Float, green: Float, blue: Float, alpha: Float)

class SharedProperties {
    
    var values: [String: AnyObject] = [:]
    var color: Color
    
    init(color: Color = (red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)) {
        self.color = color;
    }
    
    class func defaultShared() -> SharedProperties {
        return _DEFAULT_SHARED_PROPERTIES
    }
}

private let _DEFAULT_SHARED_PROPERTIES = SharedProperties()

class Polygon {
    
    let vertices: [Vertex]
    let plane: Plane
    var shared: SharedProperties
    private var cachedBoundingSphere: (center: Vector3D, radius: Double)? = nil
    private var cachedBoundingBox: (minPoint: Vector3D, maxPoint: Vector3D)? = nil
    
    init(vertices: [Vertex], shared: SharedProperties = SharedProperties.defaultShared(), plane: Plane) {
        self.vertices = vertices
        self.shared = shared
        self.plane = plane
        if (CSG.debug()) {
            assert(self.verticesConvex(), "Polygon not convex!")
        }
    }
    
    convenience init(vertices: [Vertex], shared: SharedProperties = SharedProperties.defaultShared()) {
        let plane = Plane.fromPoints(vertices[0].pos, vertices[1].pos, vertices[2].pos)
        self.init(vertices: vertices, shared: shared, plane: plane)
    }
    
    func verticesConvex() -> Bool {
        return true
    }
    
    func setColor(color: Color) {
        self.shared = SharedProperties(color: color)
    }
    
    // Extrude a polygon into the direction offsetvector
    // Returns a CSG object
    func extrude(offsetVector: Vector3D) -> CSG {
        var newPolygons = [Polygon]()
        
        let direction = self.plane.normal.dot(offsetVector)
        let startPolygon = direction > 0 ? self.flipped() : self
        newPolygons.append(startPolygon)
        let endPolygon = startPolygon.translate(offsetVector)
        let lastI = self.vertices.count - 1
        for i in 0...lastI {
            var sideFacePoints = [Vector3D]()
            let nextI = i < lastI ? i + 1 : 0
            sideFacePoints.append(startPolygon.vertices[i].pos)
            sideFacePoints.append(endPolygon.vertices[i].pos)
            sideFacePoints.append(endPolygon.vertices[nextI].pos)
            sideFacePoints.append(startPolygon.vertices[nextI].pos)
            newPolygons.append(Polygon.createFromPoints(sideFacePoints, self.shared))
        }
        newPolygons.append(endPolygon.flipped())
        return CSG(polygons: newPolygons)
    }
    
    func translate(offset: Vector3D) -> Polygon {
        return self.transform(Matrix4x4.translation(offset))
    }
    
    func boundingSphere() -> (center: Vector3D, radius: Double) {
        if self.cachedBoundingSphere == nil {
            let box = self.boundingBox()
            let center = box.minPoint.plus(box.maxPoint).times(0.5)
            let radiusVector = box.maxPoint.minus(center)
            self.cachedBoundingSphere = (center: center, radius: radiusVector.length())
        }
        return cachedBoundingSphere!
    }
    
    func boundingBox() -> (minPoint: Vector3D, maxPoint: Vector3D) {
        if self.cachedBoundingBox == nil {
            if vertices.isEmpty {
                let point = Vector3D(val: 0.0)
                self.cachedBoundingBox = (minPoint: point, maxPoint: point)
            } else {
                self.cachedBoundingBox = self.vertices.reduce1({ vertex in
                    let point = vertex.pos
                    return (minPoint: point, maxPoint: point)
                }, combine: { box, vertex in
                    let point = vertex.pos
                    return (minPoint: box.minPoint.min(point), maxPoint: box.maxPoint.max(point))
                })
            }
        }
        return cachedBoundingBox!
    }
    
    func flipped() -> Polygon {
        let newVertices = self.vertices.map() { (vertex) in vertex.flipped() }.reverse()
        return Polygon(vertices: newVertices, shared: self.shared, plane: self.plane.flipped())
    }
    
    // Affine transformation of polygon. Returns a new Polygon
    func transform(matrix: Matrix4x4) -> Polygon {
        let newVertices = self.vertices.map() { (vertex) in vertex.transform(matrix) }
        let newPlane = self.plane.transform(matrix)
        let scaleFactor = matrix.elements.0.0 * matrix.elements.1.1 * matrix.elements.2.2
        if scaleFactor < 0 {
            // the transformation includes mirroring. We need to reverse the vertex order
            // in order to preserve the inside/outside orientation:
            return Polygon(vertices: newVertices.reverse(), shared: self.shared, plane: newPlane)
        } else {
            return Polygon(vertices: newVertices, shared: self.shared, plane: newPlane)
        }
    }
    
    func stlStringValue() -> String {
        var result = ""
        if self.vertices.count >= 3 {
            // STL requires triangular polygons. If our polygon has more vertices, create
            // multiple triangles:
            let normalStl = self.plane.normal.stlStringValue()
            let firstVertexStl = self.vertices[0].stlStringValue()
            var secondVertexStl = self.vertices[1].stlStringValue()
            for i in 2..<self.vertices.count {
                result += "facet normal \(normalStl)\nouter loop\n"
                result += firstVertexStl
                result += secondVertexStl
                
                let thirdVertexStl = self.vertices[i].stlStringValue()
                result += thirdVertexStl
                result += "endloop\nendfacet\n"
                
                secondVertexStl = thirdVertexStl
            }
        }
        return result
    }
    
    func stringValue() -> String {
        var result = "Polygon plane: \(self.plane)\n"
        for vertex in self.vertices {
            result += " \(vertex)\n"
        }
        return result
    }
    
    func projectToOrthoNormalBasis(orthoBasis: OrthoNormalBasis) -> CAG {
        let points2D = self.vertices.map() { (v) in orthoBasis.to2D(v.pos) }
        let result = CAG.fromPointsNoCheck(points2D)
        let area = result.area()
        if fabs(area) < 1e-5 {
            // the polygon was perpendicular to the orthnormal plane. The resulting 2D polygon would be degenerate
            // return an empty area instead:
            return CAG()
        } else if area < 0 {
            return result.flipped()
        } else {
            return result
        }
    }
    
}