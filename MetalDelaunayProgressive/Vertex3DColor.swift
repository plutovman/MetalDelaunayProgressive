//
//  VertexWithColor.swift
//  MetalDelaunayTriangulation
//
//  Created by vladimir sierra on 5/19/17.
//  Copyright © 2017 vladimir sierra. All rights reserved.
//

struct Vertex3DColor {
  
  //var x,y,z: Float     // position data
  //var r,g,b,a: Float   // color data
  /////
  public init(x: Float, y: Float, z: Float, r: Float, g: Float, b: Float, a: Float) {
    self.x = x
    self.y = y
    self.z = z
    self.r = r
    self.g = g
    self.b = b
    self.a = a
  }
  
  public let x: Float
  public let y: Float
  public let z: Float
  public let r: Float
  public let g: Float
  public let b: Float
  public let a: Float

  
  func floatBuffer() -> [Float] {
    return [x,y,z,r,g,b,a]
  }
  
  
} // end of struct Vertex3DColor

extension Vertex3DColor: Equatable {
  /// Returns a Boolean value indicating whether two values are equal.
  ///
  /// Equality is the inverse of inequality. For any values `a` and `b`,
  /// `a == b` implies that `a != b` is `false`.
  ///
  /// - Parameters:
  ///   - lhs: A value to compare.
  ///   - rhs: Another value to compare.
  static func ==(lhs: Vertex3DColor, rhs: Vertex3DColor) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.a == rhs.a
  }
  
 }
