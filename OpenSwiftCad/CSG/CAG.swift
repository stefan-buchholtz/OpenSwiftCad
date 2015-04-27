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
    var isCanonicalized = false
    
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
    
    func expandedShell(radius: Double, resolution: Int = 8) -> CAG {
        let resolution = resolution < 4 ? 4 : resolution
        var cags = [CAG]()
        var pointMap = [String: [(Vector2D, Vector2D)]]()
        let cag = self.canonicalized()
        for side in cag.sides {
            let d = side.vertex1.pos.minus(side.vertex0.pos)
            let dl = d.length()
            if dl > 1e-5 {
                let du = d.times(1.0 / dl)
                let normal = du.normal().times(radius)
                let shellPoints = [
                    side.vertex1.pos.plus(normal),
                    side.vertex1.pos.minus(normal),
                    side.vertex0.pos.minus(normal),
                    side.vertex0.pos.plus(normal)]
                let newCAG = CAG.fromPoints(shellPoints)
                cags.append(newCAG)
                for step in 0..<2 {
                    let p1 = step == 0 ? side.vertex0.pos : side.vertex1.pos
                    let p2 = step == 0 ? side.vertex1.pos : side.vertex0.pos
                    let tag = "\(p1.x) \(p1.y)"
                    if pointMap[tag] == nil {
                        pointMap[tag] = []
                    }
                    pointMap[tag]!.append(p1, p2)
                }
            }
        }
        for (tag, sideEndPoints) in pointMap {
            var angle1: Double
            var angle2: Double
            let pCenter = sideEndPoints[0].0
            if sideEndPoints.count == 2 {
                let end1 = sideEndPoints[0].1
                let end2 = sideEndPoints[1].1
                angle1 = end1.minus(pCenter).angleDegrees()
                angle2 = end2.minus(pCenter).angleDegrees()
                if angle2 < angle1 {
                    angle2 += 360.0
                } else if angle2 >= (angle1 + 360.0) {
                    angle2 -= 360.0
                }
                if angle2 < (angle1 + 180.0) {
                    let t = angle2
                    angle2 = angle1 + 360.0
                    angle1 = t
                }
                angle1 += 90.0
                angle2 -= 90.0
            } else {
                angle1 = 0.0
                angle2 = 360.0
            }
            let fullCircle = angle2 > (angle1 + 359.999)
            if fullCircle {
                angle1 = 0.0
                angle2 = 360.0
            }
            if angle2 > (angle1 + 1e-5) {
                var points = [Vector2D]()
                if !fullCircle {
                    points.append(pCenter)
                }
                let numSteps = Int(fmax(1.0, round(Double(resolution) * (angle2 - angle1) / 360.0)))
                for step in 0...numSteps {
                    var angle = angle1 + Double(step) / Double(numSteps) * (angle2 - angle1)
                    if step == numSteps {
                        angle = angle2 // prevent rounding errors
                    }
                    if !fullCircle || step > 0 {
                        let point = pCenter.plus(vector2DfromAngleDegrees(angle).times(radius))
                        points.append(point)
                    }
                }
                let newCAG = CAG.fromPoints(points)
                cags.append(newCAG)
            }
        }
        return CAG().union(cags)
    }
    
    func expand(radius: Double, resolution: Int = 8) -> CAG {
        return self.union(self.expandedShell(radius, resolution: resolution))
    }
    
    func contract(radius: Double, resolution: Int = 8) -> CAG {
        return self.subtract(self.expandedShell(radius, resolution: resolution))
    }
    
    // extruded=cag.extrude({offset: [0,0,10], twistangle: 360, twiststeps: 100});
    // linear extrusion of 2D shape, with optional twist
    // The 2d shape is placed in in z=0 plane and extruded into direction <offset> (a CSG.Vector3D)
    // The final face is rotated <twistangle> degrees. Rotation is done around the origin of the 2d shape (i.e. x=0, y=0)
    // twiststeps determines the resolution of the twist (should be >= 1)
    // returns a CSG object
    func extrude(#offset: Vector3D, twistAngle: Double = 0.0, twistSteps: Int = 1) -> CSG {
        if self.sides.isEmpty {
            // empty CAG
            return CSG()
        }
        var steps = (twistAngle == 0.0 || twistSteps < 1) ? 1 : twistSteps
        var newPolygons = [Polygon]()
        var prevTransformedCAG: CAG
        var prevStepZ: Int
        let offset2D = Vector2D(vector: offset)
        for step in 0...steps {
            let stepFraction = Double(step) / Double(twistSteps)
            var transformedCAG = self
            let angle = twistAngle * stepFraction
            if angle != 0.0 {
                transformedCAG = transformedCAG.rotateZ(angle)
            }
            transformedCAG = transformedCAG.translate(offset2D.times(stepFraction))
            let stepZ = offset.z * stepFraction
            if step == 0 || step == steps {
                // bottom or top face
                let csgShell = transformedCAG.toCSG(stepZ - 1.0, stepZ + 1.0)
                let bounds = transformedCAG.getBounds()
                let planeCorners = [
                    (x: bounds.minPoint.x - 1.0, y: bounds.minPoint.y - 1.0),
                    (x: bounds.maxPoint.x + 1.0, y: bounds.minPoint.y - 1.0),
                    (x: bounds.maxPoint.x + 1.0, y: bounds.maxPoint.y + 1.0),
                    (x: bounds.minPoint.x - 1.0, y: bounds.maxPoint.y + 1.0)
                ]
                let planeVertices = planeCorners.map() { (x, y) in
                    Vertex(pos: Vector3D(x: x, y: y, z: stepZ))
                }
                var csgPlane = CSG(polygons: [Polygon(vertices: planeVertices)])
                var flip = (step == 0)
                if offset.z < 0.0 {
                    flip = !flip
                }
                if flip {
                    csgPlane = csgPlane.inverse()
                }
                csgPlane = csgPlane.intersect(csgShell)
                // only keep thge polygons in the z plane 
                newPolygons.extend(csgPlane.polygons.filter() { polygon in
                    fabs(polygon.plane.normal.z) > 0.99
                })
            }
            if step > 0 {
                for sideIdx in 0..<transformedCAG.sides.count {
                    let thisSide = transformedCAG.sides[sideIdx]
                    let prevSide = transformedCAG.sides[sideIdx]
                    let p1 = Polygon(vertices: [
                        Vertex(pos: thisSide.vertex1.pos.toVector3D(stepZ)),
                        Vertex(pos: thisSide.vertex0.pos.toVector3D(stepZ)),
                        Vertex(pos: prevSide.vertex0.pos.toVector3D(prevStepZ))
                    ])
                    let p2 = Polygon(vertices: [
                        Vertex(pos: thisSide.vertex1.pos.toVector3D(stepZ)),
                        Vertex(pos: prevSide.vertex0.pos.toVector3D(prevStepZ)),
                        Vertex(pos: prevSide.vertex1.pos.toVector3D(prevStepZ))
                    ])
                    if offset.z < 0.0 {
                        newPolygons.append(p1.flipped())
                        newPolygons.append(p2.flipped())
                    } else {
                        newPolygons.append(p1)
                        newPolygons.append(p2)
                    }
                }
            }
            prevTransformedCAG = transformedCAG
            prevStepZ = stepZ
        } // for step
        return CSG(polygons: newPolygons)
    }
    
    func check() -> String {
        var errors = [String]()
        if self.isSelfIntersecting() {
            errors.append("Self intersects")
        }
        var pointCount = [String: Int]()
        for side in self.sides {
            func mapPoint(p: Vector2D) {
                let tag = "\(p.x) \(p.y)"
                if pointCount[tag] == nil {
                    pointCount[tag] = 0;
                }
                pointCount[tag]! += 1
            }
            mapPoint(side.vertex0.pos)
            mapPoint(side.vertex1.pos)
        }
        for (tag, count) in pointCount {
            if count & 1 != 0 {
                errors.append("Uneven number of sides (\(count)) for point \(tag)")
            }
        }
        let area = self.area()
        if area < 1e-5 {
            errors.append("Area is \(area)")
        }
        if errors.count > 0 {
            return "\n".join(errors)
        } else {
            return ""
        }
    }
    
    func canonicalized() -> CAG {
        if self.isCanonicalized {
            return self
        } else {
            let factory = FuzzyCAGFactory()
            return factory.getCAG(self)
        }
    }
    
    func toCompactBinary() {
        assert(false, "CAG.toCompactBinary not implemented yet")
    }
    
    func getOutlinePaths() -> [Path2D] {
        let cag = self.canonicalized()
        var sideTagToSideMap = [Int: Side]()
        var vertexTagToSideTagMap = [Int: [Int]]()
        for side in self.sides {
            let sideTag = side.getTag()
            let startVertexTag = side.vertex0.getTag()
            if vertexTagToSideTagMap[startVertexTag] == nil {
                vertexTagToSideTagMap[startVertexTag] = []
            }
            vertexTagToSideTagMap[startVertexTag]?.append(sideTag)
        }
        var paths = [Path2D]()
        while true {
            var startSideTag: Int? = nil
            if let vertexTag = vertexTagToSideTagMap.keys.first {
                let sidesForThisVertex = vertexTagToSideTagMap[vertexTag]!
                startSideTag = sidesForThisVertex[0]
                if sidesForThisVertex.count > 1 {
                    vertexTagToSideTagMap[vertexTag] = [Int](sidesForThisVertex[1..<sidesForThisVertex.count])
                } else {
                    vertexTagToSideTagMap.removeValueForKey(vertexTag)
                }
            }
            if startSideTag == nil {
                // we've had all sides
                break;
            }
            
            var connectedVertexPoints = [Vector2D]()
            let sideTag = startSideTag!
            var thisSide = sideTagToSideMap[sideTag]!
            let startVertexTag = thisSide.vertex0.getTag()
            while true {
                connectedVertexPoints.append(thisSide.vertex0.pos)
                let nextVertexTag = thisSide.vertex1.getTag()
                if nextVertexTag == startVertexTag {
                    // we've closed the polygon
                    break;
                }
                assert(vertexTagToSideTagMap[nextVertexTag] != nil, "Area is not closed!")
                let nextPossibleSideTags = vertexTagToSideTagMap[nextVertexTag]!
                var nextSideIndex = -1
                if nextPossibleSideTags.count == 1 {
                    nextSideIndex == 0
                } else {
                    // more than one side starting at the same vertex. This means we have
                    // two shapes touching at the same corner
                    var bestAngle: Double? = nil
                    let thisAngle = thisSide.direction().angleDegrees()
                    for sideIndex in 0 ..< nextPossibleSideTags.count {
                        let nextPossibleSideTag = nextPossibleSideTags[sideIndex]
                        let possibleSide = sideTagToSideMap[nextPossibleSideTag]
                        let angle = possibleSide!.direction().angleDegrees()
                        var angleDiff = angle - thisAngle
                        if angleDiff < -180.0 {
                            angleDiff += 360.0
                        } else if angleDiff > 180.0 {
                            angleDiff -= 360.0
                        }
                        if nextSideIndex < 0 || angleDiff > bestAngle {
                            nextSideIndex = sideIndex
                            bestAngle = angleDiff
                        }
                    }
                }
                let nextSideTag = nextPossibleSideTags[nextSideIndex]
                if nextPossibleSideTags.count <= 1 {
                    vertexTagToSideTagMap.removeValueForKey(nextVertexTag)
                } else {
                    vertexTagToSideTagMap[nextVertexTag]!.removeAtIndex(nextSideTag)
                }
                thisSide = sideTagToSideMap[nextSideTag]!
            } // inner loop
            paths.append(Path2D(connectedVertexPoints, true))
        } // outer loop
        return paths
    }
    
    func toDxfString() -> String {
        return CAG.pathsToDxf(self.getOutlinePaths())
    }
    
    class func pathsToDxf(paths: [Path2D]) -> String {
        var str = "999\nDXF generated by OpenSwiftCad\n"
        str += "  0\nSECTION\n  2\nHEADER\n"
        str += "  0\nENDSEC\n"
        str += "  0\nSECTION\n  2\nTABLES\n"
        str += "  0\nTABLE\n  2\nLTYPE\n  70\n1\n"
        str += "  0\nLTYPE\n  2\nCONTINUOUS\n  3\nSolid Line\n  72\n65\n  73\n0\n  40\n0.0\n"
        str += "  0\nENDTAB\n"
        str += "  0\nTABLE\n  2\nLAYER\n  70\n1\n"
        str += "  0\nLAYER\n  2\nOpenJsCad\n  62\n7\n  6\ncontinuous\n"
        str += "  0\nENDTAB\n"
        str += "  0\nTABLE\n  2\nSTYLE\n  70\n0\n  0\nENDTAB\n"
        str += "  0\nTABLE\n  2\nVIEW\n  70\n0\n  0\nENDTAB\n"
        str += "  0\nENDSEC\n"
        str += "  0\nSECTION\n  2\nBLOCKS\n"
        str += "  0\nENDSEC\n"
        str += "  0\nSECTION\n  2\nENTITIES\n"
        str += "".join(paths.map() { path -> String in
            let numPointsClosed = path.points.count + (path.closed ? 1 : 0)
            let pathStr = "  0\nLWPOLYLINE\n  8\nOpenJsCad\n  90\n" + numPointsClosed + "\n  70\n" + (path.closed ? 1 : 0) + "\n"
            for pointIdx in 0 ..< numPointsClosed {
                let pointIdxWrapped = pointIdx >= path.points.count ? pointIdx - path.points.count : pointIdx
                let point = path.points[pointIndexWrapped]
                pathStr += " 10\n" + point.x + "\n 20\n" + point.y + "\n 30\n0.0\n"
            }
        })
        str += "  0\nENDSEC\n  0\nEOF\n"
        return str
    }
}