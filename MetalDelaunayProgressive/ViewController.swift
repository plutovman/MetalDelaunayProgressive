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
  var touchPointsMetal = [CGPoint]()
  
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
      touchPointsMetal = []
      let touchPoint = touch.location(in: view)
      //triangulateLogic(touchPoint: touchPoint)
      //triangulatePoints(pointCloud: [touchPoint])
      touchPointsMetal.append(touchPoint.convertSpaceDeviceToMetal())
    } // end of if let touch
  } // end of func touchesBegan()
  
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touch = touches.first  {
      let touchPoint = touch.location(in: view)
      //triangulateLogic(touchPoint: touchPoint)
      //triangulatePoints(pointCloud: [touchPoint])
      touchPointsMetal.append(touchPoint.convertSpaceDeviceToMetal())
    } // end if if let touch
  } // end of func touchesMoved()
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    print ("[touchesEnded]: adding \(touchPointsMetal.count) points to triangulate")
    //triangulatePoints(touchPointCloud: touchPointsMetal)
    retriangulatePoints(touchPointCloud: touchPointsMetal)
    
  } // end of func touchesEnded()
 
  
  // MARK: - Misc methods
  func retriangulatePoints(touchPointCloud: [CGPoint]){
    for pt2DMetal in touchPointCloud {
      let ptColor = UIColor.clear.randomColor()
      let _ = delaunayView.vertexAppendToPointCloudArrays(point: pt2DMetal, color: ptColor)
    }
    delaunayView.delaunayTriangulate()
    delaunayView.setNeedsDisplay() // redraw
  }
  
  func triangulatePoints(touchPointCloud: [CGPoint]){
    let triangleRefs: [TriangleRef] = delaunayView.delaunayContainingTrianglesForPoints(points: touchPointCloud)
    print ("[triangulatePoints]: returns \(triangleRefs.count) triangles ")
    var vertex2DArray: [Vertex2DSimple] = [Vertex2DSimple]()
    if triangleRefs.count > 0 {
      for pt2DMetal in touchPointCloud {
        //let pt2DMetal = pt2DDevice.convertSpaceDeviceToMetal() // convert to metal units
        let ptColor = UIColor.clear.randomColor()
        let vertex2D = delaunayView.vertexAppendToPointCloudArrays(point: pt2DMetal, color: ptColor)
        vertex2DArray.append(vertex2D)
      } // end of for
      delaunayView.delaunaySubTriangulatePoints(vertexArray: vertex2DArray, triangleRefArray: triangleRefs)
      
      delaunayView.setNeedsDisplay() // redraw
    } // end of if triangleRefs.count
    
  } // end of func triangulatePoints()
  
  func triangulatePointsOld(pointCloud: [CGPoint]){
    
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

