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
      let touchPoint = touch.location(in: view)
      //triangulateLogic(touchPoint: touchPoint)
      triangulatePoints(pointCloud: [touchPoint])
    } // end of if let touch
  } // end of func touchesBegan()
  
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touch = touches.first  {
      let touchPoint = touch.location(in: view)
      //triangulateLogic(touchPoint: touchPoint)
      triangulatePoints(pointCloud: [touchPoint])
    } // end if if let touch
  } // end of func touchesMoved()
 
  
  // MARK: - Misc methods
  
  func triangulatePoints(pointCloud: [CGPoint]){
    
    for pt2DDevice in pointCloud {
      let pt2DMetal = pt2DDevice.convertSpaceDeviceToMetal() // convert to metal units
      let ptColor = UIColor.clear.randomColor()
      
      let triangleRefs: [TriangleRef] = delaunayView.delaunayContainingTrianglesForPoint(p: pt2DMetal)
      print ("[triangulatePoints]: for \(pt2DDevice) found \(triangleRefs.count) triangles ")
      
      if triangleRefs.count > 0 {
        // note that if the vertex already exists in delaunayView's point cloud, the below routine does not append it and instead returns a Vertex2DSimple with an index of -1
        let vertex2D = delaunayView.vertexAppendToPointCloudArrays(point: pt2DMetal, color: ptColor)
        // only triangulate new vertices
        
        if vertex2D.index > 0 {
          /*
          for triangleRef in triangleRefs {
            delaunayView.delaunaySubTriangulatePointOld(vertex: vertex2D, triangleReference: triangleRef)
          } // end of for triangleRef
          */
          delaunayView.delaunaySubTriangulatePoint(vertex: vertex2D, triangleRefArray: triangleRefs)
          
          delaunayView.setNeedsDisplay() // redraw
        } // end of if vertex2D.index > 0
        
      } // end of if triangleRefs.count > 0
      
    } // end of for pt2DDevice in pointCloud
    
  } // end of func triangulatePoints()

  /*
  func triangulateLogic(touchPoint: CGPoint){
    let pt2DDevice = touchPoint // convert touch to Vertex2DSimple
    let pt2DMetal = pt2DDevice.convertSpaceDeviceToMetal() // convert to metal units
    let ptColor = UIColor.clear.randomColor()
    
    //print ("...touch \(pt2DDevice) or \(pt2DMetal)")
    let triangleRef = delaunayView.delaunayFindTriangleForPoint(p: pt2DMetal)
    
    
    if triangleRef.index0 == 0 &&  triangleRef.index1 == 0 && triangleRef.index2 == 0 {
      print ("...[ViewController]: no containing triangle found.  Dismissing point.")
    } else {
      // note that if the vertex already exists in delaunayView's point cloud, the below routine does not append it and instead
      // returns a Vertex2DSimple with an index of -1
      let vertex2D = delaunayView.vertexAppendToPointCloudArrays(point: pt2DMetal, color: ptColor)
      
      if vertex2D.index > 0 {
        // only triangulate new vertices
        delaunayView.delaunaySubTriangulatePoint(vertex: vertex2D, triangleReference: triangleRef)
        // redraw
        delaunayView.setNeedsDisplay()
        
      } // end of if vertex2D.index > 0
      
    } // end of if triangleRef.index0
    
  } // end of func triangulateLogic()
  */
  
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

