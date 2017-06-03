//
//  Utilities.swift
//  DelaunayTriangulationSwift
//
//  Created by Alex Littlejohn on 2016/01/08.
//  Copyright © 2016 zero. All rights reserved.
//

import UIKit




extension Double {
  static func random() -> Double {
    return Double(arc4random()) / 0xFFFFffff
  }
  
  static func random(_ min: Double, _ max: Double) -> Double {
    return Double.random() * (max - min) + min
  }
}

extension CGFloat {
  static func random(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
    return CGFloat(Double.random(Double(min), Double(max)))
  }
}

extension CGPoint {
  func convertSpaceMetalToDevice () -> CGPoint {
    let xdevice = ( x + 1.0 )  / 2.0 * UIScreen.main.bounds.size.width
    let ydevice = ( 1.0 - ( ( y + 1.0 )  / 2.0 ) ) * UIScreen.main.bounds.size.height
    return CGPoint(x: xdevice, y: ydevice)
  } // end of func convertSpaceMetalToDevice ()
  
  func convertSpaceDeviceToMetal () -> CGPoint {
    let xmetal = (x / UIScreen.main.bounds.size.width ) * 2.0 - 1.0
    //let ymetal = (y / UIScreen.main.bounds.size.height ) * 2.0 - 1.0
    let ymetal = -2.0 * ( (y / UIScreen.main.bounds.size.height ) - 1.0) - 1.0
    return CGPoint(x: xmetal, y: ymetal)
  }
}

extension Float {
  static func random(_ min: Float, _ max: Float) -> Float {
    return Float(Double.random(Double(min), Double(max)))
  }
}

extension UIColor {
  
  func hueColorWithBrightnessMultiplier(_ amount: CGFloat) -> UIColor {
    
    
    var hue         : CGFloat = 0
    var saturation  : CGFloat = 0
    var brightness  : CGFloat = 0
    var alpha       : CGFloat = 0
    if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
      return UIColor( hue: hue,
                      saturation: saturation,
                      brightness: brightness * amount,
                      alpha: alpha )
    } else {
      return self
    }
  }
} // end of extension UIColor

extension UIColor {
  
  convenience init(hex: Int) {
    let components = (
      R: CGFloat((hex >> 16) & 0xff) / 255,
      G: CGFloat((hex >> 08) & 0xff) / 255,
      B: CGFloat((hex >> 00) & 0xff) / 255
    )
    self.init(red: components.R, green: components.G, blue: components.B, alpha: 1)
  }
  
}

extension UIColor {
  func randomColor() -> UIColor {
    let hue = CGFloat( Double.random() )  // 0.0 to 1.0
    let saturation: CGFloat = 0.5  // 0.5 to 1.0, away from white
    let brightness: CGFloat = 1.0  // 0.5 to 1.0, away from black
    let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    return color
  }
}

extension UIColor
{
  /**
   Returns the components that make up the color in the RGB color space as a tuple.
   
   - returns: The RGB components of the color or nil if the color could not be converted to RGBA color space.
   */
  func getRGBAComponents() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)?
  {
    var (red, green, blue, alpha) = (CGFloat(0.0), CGFloat(0.0), CGFloat(0.0), CGFloat(0.0))
    if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    {
      return (red, green, blue, alpha)
    }
    else
    {
      return nil
    }
  }
  
  /**
   Returns the components that make up the color in the HSB color space as a tuple.
   
   - returns: The HSB components of the color or nil if the color could not be converted to HSB color space.
   */
  func getHSBAComponents() -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat)?
  {
    var (hue, saturation, brightness, alpha) = (CGFloat(0.0), CGFloat(0.0), CGFloat(0.0), CGFloat(0.0))
    if self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
    {
      return (hue, saturation, brightness, alpha)
    }
    else
    {
      return nil
    }
  }
  
  /**
   Returns the grayscale components of the color as a tuple.
   
   - returns: The grayscale components or nil if the color could not be converted to grayscale color space.
   */
  func getGrayscaleComponents() -> (white: CGFloat, alpha: CGFloat)?
  {
    var (white, alpha) = (CGFloat(0.0), CGFloat(0.0))
    if self.getWhite(&white, alpha: &alpha)
    {
      return (white, alpha)
    }
    else
    {
      return nil
    }
  }
  
  /**
   Returns a hexString equivalent of the color
   */
  
  func getHexString() -> String {
    var r:CGFloat = 0
    var g:CGFloat = 0
    var b:CGFloat = 0
    var a:CGFloat = 0
    
    getRed(&r, green: &g, blue: &b, alpha: &a)
    
    let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
    
    return String(format:"#%06x", rgb)
  }
  
  
}

extension CGColor {
  
  class func colorWithHex(_ hex: Int) -> CGColor {
    
    return UIColor(hex: hex).cgColor
    
  }
  
}


