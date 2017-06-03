//
//  Triangle2DRef.swift
//  MetalDelaunayProgressive
//
//  Created by vladimir sierra on 5/31/17.
//  Copyright © 2017 vladimir sierra. All rights reserved.
//

public struct TriangleRef {

  public init(index0: Int, index1: Int, index2: Int) {
    self.index0 = index0
    self.index1 = index1
    self.index2 = index2
  }
  
  public let index0: Int
  public let index1: Int
  public let index2: Int

}

extension TriangleRef: Equatable {
  /// Returns a Boolean value indicating whether two values are equal.
  ///
  /// Equality is the inverse of inequality. For any values `a` and `b`,
  /// `a == b` implies that `a != b` is `false`.
  ///
  /// - Parameters:
  ///   - lhs: A value to compare.
  ///   - rhs: Another value to compare.
  public static func ==(lhs: TriangleRef, rhs: TriangleRef) -> Bool {
    return lhs.index0 == rhs.index0 && lhs.index1 == rhs.index1 && lhs.index2 == rhs.index2
  }
  
}
