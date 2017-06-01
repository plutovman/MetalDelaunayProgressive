//
//  Vertex2DSimple.swift
//  DelaunayTriangulationSwift
//
//  Created by Alex Littlejohn on 2016/01/08.
//  Copyright © 2016 zero. All rights reserved.
//
import UIKit

public struct Vertex2DSimple {
  
  public init(x: CGFloat, y: CGFloat, index: Int) {
    self.x = x
    self.y = y
    self.index = index
  }
  
  public let x: CGFloat
  public let y: CGFloat
  public let index: Int
  
  func convertSpaceMetalToDevice () -> CGPoint {
    let xdevice = ( x + 1.0 )  / 2.0 * UIScreen.main.bounds.size.width
    let ydevice = ( y + 1.0 )  / 2.0 * UIScreen.main.bounds.size.height
    return CGPoint(x: xdevice, y: ydevice)
  } // end of func convertSpaceMetalToDevice ()
  
  func convertSpaceDeviceToMetal () -> CGPoint {
    let xmetal = (x / UIScreen.main.bounds.size.width ) * 2.0 - 1.0
    let ymetal = (y / UIScreen.main.bounds.size.height ) * 2.0 - 1.0
    return CGPoint(x: xmetal, y: ymetal)
  }
  
  
} // end of public struct Vertex2DSimple



extension Vertex2DSimple: Equatable { }

public func ==(lhs: Vertex2DSimple, rhs: Vertex2DSimple) -> Bool {
  return lhs.x == rhs.x && lhs.y == rhs.y
}



extension Array where Element:Equatable {
  func removeDuplicates() -> [Element] {
    var result = [Element]()
    
    for value in self {
      if result.contains(value) == false {
        result.append(value)
      }
    }
    
    return result
  }
}

extension Vertex2DSimple: Hashable {
  public var hashValue: Int {
    return "\(x)\(y)".hashValue
  }
}

extension Vertex2DSimple {
  func pointValue() -> CGPoint {
    return CGPoint(x: x, y: y)
  }
  
}
