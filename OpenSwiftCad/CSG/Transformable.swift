//
//  Transformable.swift
//  OpenSwiftCad
//
//  Created by Stefan Buchholtz on 19.04.15.
//  Copyright (c) 2015 Stefan Buchholtz. All rights reserved.
//

import Foundation

protocol Transformable {
    
    typealias TransformableObject
    
    func transform(matrix: Matrix4x4) -> TransformableObject
}