//
//  CAG.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 15.03.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//
// CAG: solid area geometry: like CSG but 2D
// Each area consists of a number of sides
// Each side is a line between 2 points

import Foundation

class CAG {
    
    let sides: [Side]
    
    // empty CAG
    init() {
        self.sides = []
    }
    
    init(sides: [Side]) {
        self.sides = sides
    }
    
    // Construct a CAG from a list of points (a polygon)
    // Rotation direction of the points is not relevant. Points can be a convex or concave polygon.
    // Polygon must not self intersect
    class func fromPoints(points: [Vector2D]) -> CAG {
        assert(points.count >= 3, "CAG.fromPoints needs at least 3 points")
        
        var result = CAG.fromPointsNoCheck(points)
        assert(!result.isSelfIntersecting(), "CAG.fromPoints: is self intersecting")
        
        let area = result.area()
        assert(fabs(area) > 1e-5, "CAG.fromPoints: degenerate polygon")
        if area < 0 {
            result = result.flipped()
        }
        return result.canonicalized()
    }
    
    // Like CAG.fromPoints but does not check if it's a valid polygon.
    // Points should rotate counter clockwise
    class func fromPointsNoCheck(points: [Vector2D]) -> CAG {
        var prevVertex = Vertex2D(pos: points.last!)
        let sides = points.map() { (point) -> Side in
            let vertex = Vertex2D(pos: point)
            let side = Side(vertex0: prevVertex, vertex1: vertex)
            prevVertex = vertex
            return side
        }
        return CAG(sides: sides)
    }
    
    // Converts a CSG to a CAG. The CSG must consist of polygons with only z coordinates +1 and -1
    // as constructed by CAG.toCSG(-1, 1). This is so we can use the 3D union(), intersect() etc
    class func fromFakeCSG(csg: CSG) -> CAG {
        let sides = csg.polygons.map() { (p) -> Side in Side.fromFakePolygon(p) }
        return CAG(sides: sides)
    }
    
    // see if the line between p0start and p0end intersects with the line between p1start and p1end
    // returns true if the lines strictly intersect, the end points are not counted!
    class func linesIntersect(p0Start: Vector2D, p0End: Vector2D, p1Start: Vector2D, p1End: Vector2D) -> Bool {
        if p0End.equals(p1Start) || p1End.equals(p0Start) {
            let d = p1End.minus(p1Start).unit().plus(p0End.minus(p0Start).unit()).length()
            if d < 1e-5 {
                return true
            }
        } else {
            let d0 = p0End.minus(p0Start)
            let d1 = p1End.minus(p1Start)
            if fabs(d0.cross(d1)) < 1e-9 {
                // lines are parallel
                return false
            }
            let alphas = CSG.solve2Linear(-d0.x, d1.x, -d0.y, d1.y, p0Start.x - p1Start.x, p0Start.y - p1Start.y)
            if alphas.0 > 1e-6 && alphas.0 < 0.999999 && alphas.1 > 1e-6 && alphas.1 < 0.999999 {
                return true
            }
        }
        return false
    }
    
    class func circle(center: Vector2D = Vector2D(val: 0.0), radius: Double = 1.0, resolution: Int = CSG.defaultResolution2D()) -> CAG {
        
        var sides = [Side]()
        var prevVertex: Vertex2D? = nil
        for i in 0...resolution {
            let radians = 2 * π * Double(i) / Double(resolution)
            let point = vector2DfromAngleRadians(radians).times(radius).plus(center)
            let vertex1 = Vertex2D(pos: point)
            if let vertex0 = prevVertex {
                sides.append(Side(vertex0: vertex0, vertex1: vertex1))
            }
            prevVertex = vertex1
        }
        return CAG(sides: sides)
    }
    
    class func rectangle(center: Vector2D = Vector2D(val: 0.0), radius: Vector2D = Vector2D(val: 1.0)) -> CAG {
        let rswap = Vector2D(x: radius.x, y: -radius.y)
        return CAG.fromPoints([center.plus(radius), center.plus(rswap), center.minus(radius), center.minus(rswap)])
    }
    
    class func roundedRectangle(center: Vector2D = Vector2D(val: 0.0), radius: Vector2D = Vector2D(val: 1.0), roundRadius: Double = 0.2, resolution: Int = CSG.defaultResolution2D()) -> CAG {
        let maxRoundRadius = fmin(radius.x, radius.y) - 0.1
        let constrainedRoundRadius = fmax(fmin(roundRadius, maxRoundRadius), 0.0)
        let newRadius = Vector2D(x: radius.x - constrainedRoundRadius, y: radius.y - constrainedRoundRadius)
        let rect = self.rectangle(center: center, radius: newRadius)
        if constrainedRoundRadius > 0.0 {
            return rect.expand(roundRadius, resolution: resolution)
        } else {
            return rect
        }
    }
    
    func stringValue() -> String {
        var result = "CAG (\(self.sides.count) sides):\n"
        for side in self.sides {
            result += " \(side)\n"
        }
        return result
    }
    
    func description() -> String {
        return self.stringValue()
    }
    
    func toCSG(z0: Double, _ z1: Double) -> CSG {
        let polygons = self.sides.map() { side in side.toPolygon3D(z0, z1) }
        return CSG(polygons: polygons)
    }
    
    func debugStringValue() -> String {
        let sortedSides = self.sides.sorted() { side0, side1 in
            return side0.vertex0.pos.x < side1.vertex0.pos.x
        }
        
        let s = sortedSides.map() { (side) -> String in
            return "(\(side.vertex0.pos.x), \(side.vertex0.pos.y)) - (\(side.vertex1.pos.x), \(side.vertex1.pos.y))"
        }
        return "\n".join(s)
    }
    
    private func combineCAGs(cags: [CAG], operation: (CSG, CSG) -> CSG) -> CAG {
        let csgs = cags.map() { (cag) in cag.toCSG(-1.0, 1.0) }
        let resultCSG = csgs.reduce(self.toCSG(-1.0, 1.0), operation).reTesselated().canonicalized()
        return CAG.fromFakeCSG(resultCSG).canonicalized()
    }
    
    func union(cags: [CAG]) -> CAG {
        return self.combineCAGs(cags) { acc, csg in acc.unionSub(csg, false, false) }
    }

    func union(cag: CAG) -> CAG {
        return self.union([cag])
    }
    
    func subtract(cags: [CAG]) -> CAG {
        return self.combineCAGs(cags) { acc, csg in acc.subtractSub(csg, false, false) }
    }
    
    func subtract(cag: CAG) -> CAG {
        return subtract([cag])
    }
    
    func intersect(cags: [CAG]) -> CAG {
        return self.combineCAGs(cags) { acc, csg in acc.intersectSub(csg, false, false) }
    }
    
    func intersect(cag: CAG) -> CAG {
        return intersect([cag])
    }
    
    func transform(matrix: Matrix4x4) -> CAG {
        let newSides = self.sides.map() { side in side.transform(matrix) }
        let result = CAG(sides: newSides)
        if matrix.isMirroring() {
            return result.flipped()
        } else {
            return result
        }
    }
    
    // see http://local.wasp.uwa.edu.au/~pbourke/geometry/polyarea/ :
    // Area of the polygon. For a counter clockwise rotating polygon the area is positive, otherwise negative
    func area() -> Double {
        let polygonArea = self.sides.reduce(0.0) { area, side in
            area + side.vertex0.pos.cross(side.vertex1.pos)
        }
        return polygonArea * 0.5
    }
    
    func flipped() -> CAG {
        let newSides = self.sides.map() { side in side.flipped() }
        return CAG(sides: newSides.reverse())
    }
    
    func getBounds() -> (minPoint: Vector2D, maxPoint: Vector2D) {
        if self.sides.isEmpty {
            let point = Vector2D(val: 0.0)
            return (minPoint: point, maxPoint: point)
        } else {
            let point = sides[0].vertex0.pos
            return self.sides.reduce((minPoint: point, maxPoint: point)) { bounds, side in
                let minPoint = bounds.minPoint.min(side.vertex0.pos).min(side.vertex1.pos)
                let maxPoint = bounds.maxPoint.max(side.vertex0.pos).max(side.vertex1.pos)
                return (minPoint: minPoint, maxPoint: maxPoint)
            }
        }
    }
    
    func center(newCenter: Vector2D) -> CAG {
        let bounds = self.getBounds()
    }
    
    func isSelfIntersecting() -> Bool {
        for i in 0 ..< self.sides.count {
            let side0 = self.sides[i]
            for j in i+1 ..< self.sides.count {
                let side1 = self.sides[j]
                if CAG.linesIntersect(side0.vertex0.pos, p0End: side0.vertex1.pos, p1Start: side1.vertex0.pos, p1End: side1.vertex1.pos) {
                    return true
                }
            }
        }
        return false
    }
    
    func expandedShell(radius: Double, resolution: Int = 8) {
        let resolution = resolution < 4 ? 4 : resolution
        var cags = [CAG]()
        var pointMap = [(Int): (Vector2D, Vector2D)]()
        let cag = self.canonicalized()
        for side in cag.sides {
            let d = side.vertex1.pos.minus(side.vertex0.pos)
            let dl = d.length()
            
        }
    }
    
    func canonicalized() -> CAG {
        
    }
    
}