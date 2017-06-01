//
//  ViewController.swift
//  MetalDelaunayProgressive
//
//  Created by vladimir sierra on 5/31/17.
//  Copyright © 2017 vladimir sierra. All rights reserved.
//

import UIKit

class ViewController: UIViewController, DelaunayTriangulationMetalViewDelegate {

  var delaunayView: DelaunayTriangulationMetalView!
  
  let fpsLabel = UILabel(frame: CGRect(x: 0, y: 20, width: 400, height: 20))
  
  // MARK: - Override methods
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    delaunayView = DelaunayTriangulationMetalView(frame: UIScreen.main.bounds)
    delaunayView.MetalViewDelegate = self
    
    //delaunayView.enableSetNeedsDisplay = true // needed so we can call setNeedsDisplay() locally to force a display update
    //delaunayView.isPaused = true  // may not be needed, as the enableSetNeedsDisplay flag above seems to pause screen activity upon start anyway
    
    view.addSubview(delaunayView)
    
    fpsLabel.textColor = UIColor.yellow
    view.addSubview(fpsLabel)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  } // end of override func didReceiveMemoryWarning()
  
  override func viewDidLayoutSubviews(){
    delaunayView.frame = view.bounds
  } // end of override func viewDidLayoutSubviews()
  
  // MARK: - Delegate methods
  
  func fpsUpdate(fps: Int, triangleCount: Int) {
    let description = "fps: \(Int(fps)), triangles: \(triangleCount))"
    
    DispatchQueue.main.async
      {
        //print ("...updating time: \(description)")
        self.fpsLabel.text = description
    } // end of DispatchQueue.main.async
    
  } // end of func fpsUpdate()


} // end of class ViewController: UIViewController()

