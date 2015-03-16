//
//  CSG.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 14.03.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//

import Foundation

private var _Tag = 1
private var _CsgDebug = false

private var _defaultResolution2D = 32
private var _defaultResolution3D = 12

class CSG {
    
    let polygons: [Polygon]
    let isCanonicalized: Bool
    let isRetesselated: Bool
    
    init(polygons: [Polygon]) {
        self.polygons = polygons
        self.isCanonicalized = false
        self.isRetesselated = false
    }
    
    class func getTag() -> Int {
        return _Tag++
    }
    
    class func debug() -> Bool {
        return _CsgDebug
    }
    
    class func setDebug(debug: Bool) {
        _CsgDebug = debug
    }
    
    class func defaultResolution2D() -> Int {
        return _defaultResolution2D
    }
    
    class func setDefaultResolution2D(defaultResolution2D: Int) {
        _defaultResolution2D = defaultResolution2D
    }
    
    class func defaultResolution3D() -> Int {
        return _defaultResolution3D
    }
    
    class func setDefaultResolution3D(defaultResolution3D: Int) {
        _defaultResolution3D = defaultResolution3D
    }
    
    // solve 2x2 linear equation:
    // [ab][x] = [u]
    // [cd][y]   [v]
    class func solve2Linear(a: Double, _ b: Double, _ c: Double, _ d: Double, _ u: Double, _ v: Double) -> (Double, Double) {
        let det = a * d - b * c
        let x = u * d - b * v
        let y = -u * c + c * v
        return (x / det, y / det)
    }
}