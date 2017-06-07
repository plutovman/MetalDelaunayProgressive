//
//  ViewController.swift
//  MetalDelaunayProgressive
//
//  Created by vladimir sierra on 5/31/17.
//  Copyright © 2017 vladimir sierra. All rights reserved.
//

import UIKit

class ViewController: UIViewController, DelaunayTriangulationMetalViewDelegate {
  
  // this is a simple drawing application that performs delaunay triangulation of points that are drawn via touches methods
  // note that the triangulation happens once touchesEnded() gets called, at which point all the points drawn get appended
  // to a pointCloud that then gets sent to the

  var delaunayView: DelaunayTriangulationMetalView!
  var touchPoints = [CGPoint]()
  
  let fpsLabel = UILabel(frame: CGRect(x: 0, y: 20, width: 400, height: 20))
  
  // MARK: - Override methods
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    delaunayView = DelaunayTriangulationMetalView(frame: UIScreen.main.bounds)
    delaunayView.MetalViewDelegate = self
    
    delaunayView.enableSetNeedsDisplay = true // needed so we can call setNeedsDisplay() locally to force a display update
    delaunayView.isPaused = true  // may not be needed, as the enableSetNeedsDisplay flag above seems to pause screen activity upon start anyway
    
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
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    
    // the design strategy regarding vertex addition via vertexAppend() needs to:
    // 1. from view's touch, convert touch coordinates (in device space) to Vertex3DColor coordinates (in metal space)
    // 3. find out the triangle that contains the new point
    // 2. append vertex to pointCloud arrays
    
    // 4. delete triangle ref from [TriangleRef]
    // 5. create a new [Vertex2DSimple] array containing index references to the new point coord, plus refs to the coordinates of the triangle just deleted
    // 6. run delaunayComputeColoredMesh() on that array which will return an updated [TriangleRef]
    
    if let touch = touches.first  {
      touchPoints = []
      let touchPoint = touch.location(in: view)
      touchPoints.append(touchPoint)
    } // end of if let touch
  } // end of func touchesBegan()
  
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touch = touches.first  {
      let touchPoint = touch.location(in: view)
      touchPoints.append(touchPoint)
    } // end if if let touch
  } // end of func touchesMoved()
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    print ("[touchesEnded]: adding \(touchPoints.count) points to triangulate")
    //triangulatePoints(touchPointCloud: touchPoints)
    triangulatePointCloud(touchPointCloud: touchPoints)
    
  } // end of func touchesEnded()
 
  
  // MARK: - Misc methods
  func triangulatePointCloud(touchPointCloud: [CGPoint]){
    for pt2DDevice in touchPointCloud {
      let pt2DMetal = pt2DDevice.convertSpaceDeviceToMetal()
      let ptColor = UIColor.clear.randomColor()
      let _ = delaunayView.vertexAppendToPointCloudArrays(point: pt2DMetal, color: ptColor)
    }
    delaunayView.delaunayTriangulateAndPopulateRenderArray()
    delaunayView.setNeedsDisplay() // redraw
  }
  
  

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

