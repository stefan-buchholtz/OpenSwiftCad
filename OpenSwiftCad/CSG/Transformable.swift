//
//  Transformable.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 19.04.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//

import Foundation

protocol Transformable {
    
    typealias TransformableObject: Transformable
    
    func transform(matrix: Matrix4x4) -> TransformableObject
}

// convenience transformation functions
func mirrored<T: Transformable>(object: T, plane: Plane) -> T {
    return object.transform(Matrix4x4.mirroring(plane)) as! T
}

func mirroredX<T: Transformable>(object: T) -> T {
    let plane = Plane(normal: Vector3D(x: 1.0, y: 0.0, z: 0.0), w: 0.0)
    return object.transform(Matrix4x4.mirroring(plane)) as! T
}

func mirroredY<T: Transformable>(object: T) -> T {
    let plane = Plane(normal: Vector3D(x: 0.0, y: 1.0, z: 0.0), w: 0.0)
    return object.transform(Matrix4x4.mirroring(plane)) as! T
}

func mirroredZ<T: Transformable>(object: T) -> T {
    let plane = Plane(normal: Vector3D(x: 0.0, y: 0.0, z: 1.0), w: 0.0)
    return object.transform(Matrix4x4.mirroring(plane)) as! T
}

func translate<T: Transformable>(object: T, vector: Vector3D) -> T {
    return object.transform(Matrix4x4.translation(vector)) as! T
}

func scale<T: Transformable>(object: T, factor: Vector3D) -> T {
    return object.transform(Matrix4x4.scaling(factor)) as! T
}

func scale<T: Transformable>(object: T, factor: Double) -> T {
    return object.transform(Matrix4x4.scaling(Vector3D(val: factor))) as! T
}

func rotateX<T: Transformable>(object: T, degrees: Double) -> T {
    return object.transform(Matrix4x4.rotationX(degrees)) as! T
}

func rotateY<T: Transformable>(object: T, degrees: Double) -> T {
    return object.transform(Matrix4x4.rotationY(degrees)) as! T
}

func rotateZ<T: Transformable>(object: T, degrees: Double) -> T {
    return object.transform(Matrix4x4.rotationZ(degrees)) as! T
}

func rotate<T: Transformable>(object: T, center: Vector3D, axis: Vector3D, degrees: Double) -> T {
    return object.transform(Matrix4x4.rotationFromCenter(center, aroundAxis: axis, byDegrees: degrees)) as! T
}

