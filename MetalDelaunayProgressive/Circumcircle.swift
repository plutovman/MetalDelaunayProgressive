//
//  Circumcircle.swift
//  DelaunayTriangulationSwift
//
//  Created by Alex Littlejohn on 2016/01/08.
//  Copyright © 2016 zero. All rights reserved.
//

/// Represents a bounding circle for a set of 3 vertices
import UIKit

internal struct Circumcircle {
    let vertex1: Vertex2DSimple
    let vertex2: Vertex2DSimple
    let vertex3: Vertex2DSimple
    let x: CGFloat
    let y: CGFloat
    let rsqr: CGFloat
}
