//
//  Path2D.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 21.03.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//

import Foundation

class Path2D {
    
    let points: [Vector2D]
    let closed: Bool
    
    init(points: [Vector2D], closed: Bool) {
        var newPoints = [Vector2D]()
        var prevPoint: Vector2D?
        if closed && !points.isEmpty {
            prevPoint = points.last
        }
        for point in points {
            if prevPoint == nil || point.distanceTo(prevPoint!) >= 1e-5 {
                newPoints.append(point)
            }
            prevPoint = point
        }
        self.points = newPoints
        self.closed = closed
    }
    
    /*
    Construct a (part of a) circle. Parameters:
    center: the center point of the arc (CSG.Vector2D or array [x,y])
    radius: the circle radius (float)
    startangle: the starting angle of the arc, in degrees
    0 degrees corresponds to [1,0]
    90 degrees to [0,1]
    and so on
    endangle: the ending angle of the arc, in degrees
    resolution: number of points per 360 degree of rotation
    maketangent: adds two extra tiny line segments at both ends of the circle
    this ensures that the gradients at the edges are tangent to the circle
    Returns a CSG.Path2D. The path is not closed (even if it is a 360 degree arc).
    close() the resultin path if you want to create a true circle.
    */
    class func arc(center: Vector2D, radius: Double = 1.0, startAngle: Double = 0.0, endAngle: Double = 360.0, resolution: Int = CSG.defaultResolution2D(), makeTangent: Bool = false) -> Path2D {
        // no need to make multiple turns:
        var end = endAngle
        while end - startAngle >= 720.0 {
            end -= 360.0
        }
        while end - startAngle <= -720.0 {
            end += 360.0
        }
        var points = [Vector2D]()
        let absAngleDiff = fabs(end - startAngle)
        if absAngleDiff < 1e-5 {
            let point = vector2DfromAngleDegrees(startAngle).times(radius)
            points.append(point.plus(center))
        } else {
            var numSteps = Int(floor(Double(resolution) * absAngleDiff / 360.0)) + 1
            var edgeStepSize = Double(numSteps) * 0.5 / absAngleDiff // step size for half a degree
            edgeStepSize = fmin(edgeStepSize, 0.25)
            if makeTangent {
                numSteps += 2
            }
            for i in 0 ... numSteps {
                var step = Double(i)
                if makeTangent {
                    step = Double(i - 1) * (Double(numSteps) - 2.0 * edgeStepSize) / Double(numSteps) + edgeStepSize
                    if step < 0.0 {
                        step = 0.0
                    }
                    if step > Double(numSteps) {
                        step = Double(numSteps)
                    }
                }
            }
        }
        return Path2D(points: points, closed: false)
    }
    
    func concat(otherPath: Path2D) -> Path2D {
        assert(!self.closed && !otherPath.closed, "Paths must not be closed")
        return Path2D(points: self.points + otherPath.points, closed: false)
    }
    
    func appendPoint(point: Vector2D) -> Path2D {
        assert(!self.closed, "Path must not be closed")
        return Path2D(points: self.points + [point], closed: false)
    }
    
    func close() -> Path2D {
        return Path2D(points: self.points, closed: true)
    }
    
    func rectangularExtrude(#width: Double, height: Double, resolution: Int) -> CSG {
        let cag = self.expandToCAG(pathRadius: width / 2.0, resolution: resolution)
        return cag.extrude(offset: Vector3D(x: 0.0, y: 0.0, z: height))
    }
    
    func expandToCAG(#pathRadius: Double, resolution: Int) -> CAG {
        var sides = [Side]()
        let startIndex = (self.closed && self.points.count > 2) ? -1 : 0
        var prevVertex: Vertex2D? = nil
        for i in startIndex..<self.points.count {
            let point = i >= 0 ? self.points[i] : self.points.last!
            let vertex = Vertex2D(pos: point)
            if let prevVertex_ = prevVertex {
                let side = Side(vertex0: prevVertex_, vertex1: vertex)
                sides.append(side)
            }
            prevVertex = vertex
        }
        let shellCag = CAG(sides: sides)
        return shellCag.expandedShell(pathRadius, resolution: resolution)
    }
    
    func innerCAG() -> CAG {
        assert(self.closed, "The path should be closed")
        return CAG.fromPoints(self.points)
    }
    
    func transform(matrix: Matrix4x4) -> Path2D {
        let newPoints = self.points.map() { point in point.multiply4x4(matrix) }
        return Path2D(points: newPoints, closed: self.closed)
    }
    
}