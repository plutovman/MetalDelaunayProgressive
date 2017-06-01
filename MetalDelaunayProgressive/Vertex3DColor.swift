//
//  VertexWithColor.swift
//  MetalDelaunayTriangulation
//
//  Created by vladimir sierra on 5/19/17.
//  Copyright © 2017 vladimir sierra. All rights reserved.
//

struct Vertex3DColor{
  
  var x,y,z: Float     // position data
  var r,g,b,a: Float   // color data
  
  func floatBuffer() -> [Float] {
    return [x,y,z,r,g,b,a]
  }
  
}
