//
//  Triangle.swift
//  DelaunayTriangulationSwift
//
//  Created by Alex Littlejohn on 2016/01/08.
//  Copyright © 2016 zero. All rights reserved.
//

/// A simple struct representing 3 vertices
import UIKit
import GLKit

public struct Triangle2D {
  let xcoords: [CGFloat]
  let ycoords: [CGFloat]
  let xmin: CGFloat
  let xmax: CGFloat
  let ymin: CGFloat
  let ymax: CGFloat
  public init(vertex1: Vertex2DSimple, vertex2: Vertex2DSimple, vertex3: Vertex2DSimple) {
    self.vertex1 = vertex1
    self.vertex2 = vertex2
    self.vertex3 = vertex3
    xcoords = [self.vertex1.x, self.vertex2.x, self.vertex3.x]
    ycoords = [self.vertex1.y, self.vertex2.y, self.vertex3.y]
    xmin = xcoords.min()!
    xmax = xcoords.max()!
    ymin = ycoords.min()!
    ymax = ycoords.max()!
  }
  
  public let vertex1: Vertex2DSimple
  public let vertex2: Vertex2DSimple
  public let vertex3: Vertex2DSimple
  
  func containsPoint(point: CGPoint) -> Bool {
    // the first if test gets rid of obvious candidate triangles whose bbox don't intersect with the given point
    if (point.x >= xmin && point.x <= xmax && point.y >= ymin && point.y <= ymax) {
      
      // now that we're only considering serious candidates, we set up a more elaborate test
      // using the barycentric technique found in http://blackpawn.com/texts/pointinpoly/
      
      let va = GLKVector2Make(Float(vertex1.x), Float(vertex1.y))
      let vb = GLKVector2Make(Float(vertex2.x), Float(vertex2.y))
      let vc = GLKVector2Make(Float(vertex3.x), Float(vertex3.y))
      let vp = GLKVector2Make(Float(point.x), Float(point.y))
      /*
      let v0 = vc - va
      let v1 = vb - va
      let v2 = vp - va
      */
      
      // compute vectors
      let v0 = GLKVector2Subtract(vc, va)
      let v1 = GLKVector2Subtract(vb, va)
      let v2 = GLKVector2Subtract(vp, va)
      // compute dot products
      let dot00 = GLKVector2DotProduct(v0, v0)
      let dot01 = GLKVector2DotProduct(v0, v1)
      let dot02 = GLKVector2DotProduct(v0, v2)
      let dot11 = GLKVector2DotProduct(v1, v1)
      let dot12 = GLKVector2DotProduct(v1, v2)
      // compute barycentric coords
      let inversedenom = 1 / (dot00 * dot11 - dot01 * dot01)
      let u = (dot11 * dot02 - dot01 * dot12) * inversedenom
      let v = (dot00 * dot12 - dot01 * dot02) * inversedenom
      

      if (u >= 0 && v >= 0 && (u + v) < 1) {
        return true
      } else {
        return false
      }
      
    } else {
      return false
    }
    
  } // end of func containsPoint()
  
  
  
  
  
} // end of public struct Triangle
