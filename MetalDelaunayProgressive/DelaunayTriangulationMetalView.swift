//
//  DelaunayTriangulationMetalView.swift
//  MetalDelaunayProgressive
//
//  Created by vladimir sierra on 5/31/17.
//  Copyright © 2017 vladimir sierra. All rights reserved.
//

import MetalKit

protocol DelaunayTriangulationMetalViewDelegate: NSObjectProtocol{
  func fpsUpdate (fps: Int, triangleCount: Int)
}

class DelaunayTriangulationMetalView: MTKView {
  
  var pipelineState: MTLComputePipelineState!
  var defaultLibrary: MTLLibrary! = nil
  var commandQueue: MTLCommandQueue! = nil
  var renderPipeline: MTLRenderPipelineState!
  var errorFlag:Bool = false

  var pointCloud3DMetal : [Vertex3DColor]! // stores x,y,z,r,g,b,a points in metal-space units
  var pointCloud2DMetal : [Vertex2DSimple]! // stores x,y points in metal-space units
  var delaunayTriangleMeshOrderedVertices : [Vertex3DColor]! // stores vertices to be rendered by metal
  
  var delaunayTriangleRefArray: [TriangleRef]! // stores triangles as index references to pointCloudMetal array
  var triangleCount: Int = 0
  let fpsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 20))
  var frameCounter: Int = 0
  var frameStartTime = CFAbsoluteTimeGetCurrent()
  
  
  weak var MetalViewDelegate: DelaunayTriangulationMetalViewDelegate?
  
  ////////////////////
  init(frame: CGRect) {
    
    super.init(frame: frame, device: MTLCreateSystemDefaultDevice())
    
    metalSetupRenderPipeline() // one-time metal initialization
    metalInitializeDrawingCanvas () // set up some basic drawing vertices
    
  } // end of init()
  
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Override methods
  override func draw(_ rect: CGRect) {
    
    step() // needed to update frame counter
    autoreleasepool {
      // if we want to generate triangles via the view's internal timer, we want to
      // call a generation routine (such as metalInitializeDrawingCanvas() AND, we must take care
      // to set the view's .enableSetNeedsDisplay = true  and .isPaused = true
      //metalInitializeDrawingCanvas () // set up some basic drawing vertices
      
      // regardless of whether we are updating manually via user event (such as touchesBegan)
      // or we use the view's internal timer, we must always update state via metalRenderColoredMesh()
      metalRenderColoredMesh()
    }
    
  }
  
  // MARK: - Metal methods
  
  func step() {
    frameCounter += 1
    if frameCounter == 100
    {
      let frametime = (CFAbsoluteTimeGetCurrent() - frameStartTime) / 100
      MetalViewDelegate?.fpsUpdate(fps: Int(1 / frametime), triangleCount: delaunayTriangleRefArray.count) // let the delegate know of the frame update
      print ("...frametime: \((Int(1/frametime)))")
      frameStartTime = CFAbsoluteTimeGetCurrent() // reset start time
      frameCounter = 0 // reset counter
    }
  } // end of func step()
  
  func metalInitializeDrawingCanvas () {
    initializeMetalArrays() // zero out geometry arrays
    
    setupVerticesViewBBox() // set up perimeter vertices
    
    //setupVerticesRandom(numVertices: 100) // add a few vertices throughout
    
    delaunayTriangleRefArray = Delaunay().triangulate(vertices: pointCloud2DMetal) //  perform delaunay triangulation
    
    delaunayPopulateRenderArray(triangleRefArray: delaunayTriangleRefArray) // populate delaunayTriangleMeshOrderedVertices array that will eventually get rendered
  } // end of func initializeDrawingCanvas ()
  
  func metalSetupRenderPipeline(){
    
    // Steps required to set up metal for rendering:
    
    // 1. Create a MTLDevice
    // 2. Create a Command Queue
    // 3. Access the custom shader library
    // 4. Compile shaders from library
    // 5. Create a render pipeline
    // 6. Set buffer size of objects to be drawn
    // 7. Draw to pipeline through a renderCommandEncoder
    
    
    // 1. Create a MTLDevice
    guard let device = MTLCreateSystemDefaultDevice() else {
      errorFlag = true
      //particleLabDelegate?.particleLabMetalUnavailable()
      return
    }
    
    // 2. Create a Command Queue
    commandQueue = device.makeCommandQueue()
    
    // 3. Access the custom shader library
    defaultLibrary = device.newDefaultLibrary()
    
    // 4. Compile shaders from library
    let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
    let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
    
    // 5a. Define render pipeline settings
    let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
    renderPipelineDescriptor.vertexFunction = vertexProgram
    renderPipelineDescriptor.sampleCount = self.sampleCount
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat
    renderPipelineDescriptor.fragmentFunction = fragmentProgram
    
    // 5b. Compile renderPipeline with above renderPipelineDescriptor
    do {
      renderPipeline = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    } catch let error as NSError {
      print("render pipeline error: " + error.description)
    }
    
    // initialize counter variables
    frameStartTime = CFAbsoluteTimeGetCurrent()
    frameCounter = 0
    
  } // end of metalSetupRenderPipeline
  
  func metalRenderColoredMesh(){
    // 6. Set buffer size of objects to be drawn
    //let dataSize = vertexCount * MemoryLayout<Vertex3DColor>.size // size of the vertex data in bytes
    let dataSize = delaunayTriangleMeshOrderedVertices.count * MemoryLayout<Vertex3DColor>.stride // apple recommendation
    let vertexBuffer: MTLBuffer = device!.makeBuffer(bytes: delaunayTriangleMeshOrderedVertices, length: dataSize, options: []) // create a new buffer on the GPU
    let renderPassDescriptor: MTLRenderPassDescriptor? = self.currentRenderPassDescriptor
    // If the renderPassDescriptor is valid, begin the commands to render into its drawable
    if renderPassDescriptor != nil {
      // Create a new command buffer for each tessellation pass
      
      let commandBuffer: MTLCommandBuffer? = commandQueue.makeCommandBuffer()
      // Create a render command encoder
      // 7a. Create a renderCommandEncoder four our renderPipeline
      let renderCommandEncoder: MTLRenderCommandEncoder? = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
      renderCommandEncoder?.label = "Render Command Encoder"
      renderCommandEncoder?.setTriangleFillMode(.lines)
      //////////renderCommandEncoder?.pushDebugGroup("Tessellate and Render")
      renderCommandEncoder?.setRenderPipelineState(renderPipeline!)
      renderCommandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
      // most important below: we tell the GPU to draw a set of triangles, based on the vertex buffer. Each triangle consists of three vertices, starting at index 0 inside the vertex buffer, and there are vertexCount/3 triangles total
      //renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount/3)
      renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: delaunayTriangleMeshOrderedVertices.count)
      
      ///////////renderCommandEncoder?.popDebugGroup()
      renderCommandEncoder?.endEncoding() // finalize renderEncoder set up
      
      commandBuffer?.present(self.currentDrawable!) // needed to make sure the new texture is presented as soon as the drawing completes
      
      // 7b. Render to pipeline
      commandBuffer?.commit() // commit and send task to gpu
      
    } // end of if renderPassDescriptor
    
  }// end of func metalRenderColoredMesh()
  
  // MARK: - Delaunay methods
  
  func initializeMetalArrays() {
    pointCloud3DMetal = []
    pointCloud2DMetal = []
    delaunayTriangleMeshOrderedVertices = []
    

  } // end of func initializeMetalArrays()
  
  func vertexAppendToPointCloudArrays (point: CGPoint, color: UIColor) -> Vertex2DSimple {

    let rgba = color.getRGBAComponents()!
    let x0 = Float(point.x)
    let y0 = Float(point.y)
    let r0 = Float(rgba.red)
    let g0 = Float(rgba.green)
    let b0 = Float(rgba.blue)
    let a0 = Float(1.0)
    var returnedVertex2D: Vertex2DSimple
    
    let vertex2D = Vertex2DSimple(x: CGFloat(x0), y: CGFloat(y0), index: pointCloud2DMetal.count)
    let vertex3D = Vertex3DColor(x: x0, y: y0, z: 0.0, r: r0, g: g0, b: b0, a: a0)
    
    // append vertex to master 3D and 2D arrays ONLY if it's a new vertex
    if pointCloud2DMetal.contains(vertex2D) {
      print ("...[vertexAppendToPointCloudArrays]: skipping already existing vertex")
      returnedVertex2D = Vertex2DSimple(x: CGFloat(x0), y: CGFloat(y0), index: -1) // if the pointCloud already has this vertex, we return a dummy one to throw away
    } else {
      pointCloud3DMetal.append(vertex3D)
      pointCloud2DMetal.append(vertex2D)
      returnedVertex2D = vertex2D
    }
    //print ("...returned vertex2D: \(returnedVertex2D)")
    
    return returnedVertex2D
  } // end of func vertexAppend
  
  
  
  
  // overall note about vertices.  we WANT to work with Vertex3DColor from the get go.
  // ho
  
  // the design strategy regarding vertex handling is as follows:
  // 1. store  vertices in master pointCloud3DMetal
  // 2. build pointCloud2DMetal array of [Vertex2DSimple] from [Vertex3DColor] in previous step . Remember to store index placement in new field!
  // 3. Delaunay().triangulate(pointCloud2DMetal) returns an aray of [TriangleRef] that refer to Vertex3DColor indices
  // 4. metalRenderColoredMesh() must build a local [Vertex3DColor] array by stepping through triangles' indices in step 3
  
  // the design strategy regarding vertex addition via vertexAppend() needs to:
  // 1. from view's touch, convert touch coordinates (in device space) to Vertex3DColor coordinates (in metal space)
  // 2. append vertex to pointCloud3DMetal [Vertex3DColor] array
  // 3. find out the triangle that contains the new point
  // 4. delete triangle ref from [TriangleRef]
  // 5. create a new [Vertex2DSimple] array containing index references to the new point coord, plus refs to the coordinates of the triangle just deleted
  // 6. run delaunayPopulateRenderArray() on that array which will return an updated [TriangleRef]
  
  func setupVerticesViewBBox() {
    
    // note on the use of arrays:
    // pointCloud3DMetal is the master 3d array that we use to store vertex data
    // pointCloud2DMetal is the condensed and indexed array we use to do delaunay triangulation computations
    // delaunayTriangleMeshOrderedVertices is the 3d array that stored ordered coordinates that define delaunay triangles
    
    // define bbox vertices
    let ul = CGPoint(x: -1.0, y:  1.0)
    let um = CGPoint(x:  0.0, y:  1.0)
    let ur = CGPoint(x:  1.0, y:  1.0)
    
    let ml = CGPoint(x: -1.0, y:  0.0)
    let mr = CGPoint(x:  1.0, y:  0.0)
    
    let ll = CGPoint(x: -1.0, y: -1.0)
    let lm = CGPoint(x:  0.0, y: -1.0)
    let lr = CGPoint(x:  1.0, y: -1.0)
    
    // append vertices to point cloud arrays
    let _ = vertexAppendToPointCloudArrays(point: ul, color: UIColor.red)
    let _ = vertexAppendToPointCloudArrays(point: um, color: UIColor.blue)
    let _ = vertexAppendToPointCloudArrays(point: ur, color: UIColor.green)
    
    let _ = vertexAppendToPointCloudArrays(point: ml, color: UIColor.green)
    let _ = vertexAppendToPointCloudArrays(point: mr, color: UIColor.yellow)
    
    let _ = vertexAppendToPointCloudArrays(point: ll, color: UIColor.blue)
    let _ = vertexAppendToPointCloudArrays(point: lm, color: UIColor.green)
    let _ = vertexAppendToPointCloudArrays(point: lr, color: UIColor.magenta)
 
    
  } // end of func setupVerticesViewBBox()
  
  func setupVerticesRandom(numVertices: Int) {
    
    for _ in 0 ... numVertices {
      let x0 = CGFloat.random(-1.0, 1.0)
      let y0 = CGFloat.random(-1.0, 1.0)
      let pt2DMetal = CGPoint(x: x0, y: y0)
      let colorRandom = UIColor.clear.randomColor()
      let _ = vertexAppendToPointCloudArrays(point: pt2DMetal, color: colorRandom)
 
    } // end of for
    //print ("...[DelaunayTriangulationMetalView] 2D size: \(pointCloud2DMetal.count) 3D size: \(pointCloud3DMetal.count)")
    
  } // end of func setupVerticesRandom()
  
  /*
  func delaunayFindTriangleForPoint(p: CGPoint) -> TriangleRef {
    var cnt = 0
    var searchActive = true
    print ("...about to search through \(delaunayTriangleRefArray.count) triangles")
    
    while searchActive && cnt < delaunayTriangleRefArray.count {
      let triangleRef = delaunayTriangleRefArray[cnt]
      let v0 = pointCloud2DMetal[triangleRef.index0]
      let v1 = pointCloud2DMetal[triangleRef.index1]
      let v2 = pointCloud2DMetal[triangleRef.index2]
      let triangle = Triangle2D(vertex0: v0, vertex1: v1, vertex2: v2)
      if triangle.containsPoint(point: p) {
        searchActive = false // stop search.  we've found our guy
        //print ("......\(cnt) :: \(p) : \(triangle.vertex1) \(triangle.vertex2) \(triangle.vertex3)")
        return triangleRef
        
      } else {
        
      }// end of if
      cnt += 1
    } // end of while
    print ("...[delaunayFindTriangleForPoint]: bad point \(cnt) : \(p) ")
    return TriangleRef(index0: 0, index1: 0, index2: 0) // it feels like bad design to return a TriangleRef with dummy indices...)
  
    
  } // end of func delaunayFindTriangle()
  */
  
  func delaunayContainingTrianglesForPoint(p: CGPoint) -> [TriangleRef] {
    var triangleRefs = [TriangleRef]()
    
    for triangleRef in delaunayTriangleRefArray {
      let v0 = pointCloud2DMetal[triangleRef.index0]
      let v1 = pointCloud2DMetal[triangleRef.index1]
      let v2 = pointCloud2DMetal[triangleRef.index2]
      let triangle = Triangle2D(vertex0: v0, vertex1: v1, vertex2: v2)
      if triangle.containsPoint(point: p) {
        triangleRefs.append(triangleRef)
      } // end of if
    } // end of for triangleRef
    return triangleRefs
  } // end of func delaunayContainingTrianglesForPoints()
  func delaunaySubTriangulatePoint(vertex: Vertex2DSimple, triangleRefArray: [TriangleRef]) {
    
    for triangleReference in triangleRefArray {
      let v0 = pointCloud2DMetal[triangleReference.index0]
      let v1 = pointCloud2DMetal[triangleReference.index1]
      let v2 = pointCloud2DMetal[triangleReference.index2]
      let vertexArray = [v0,v1,v2]
      
      let subTriangleArrayRef = Delaunay().triangulateSimple(vertices: vertexArray, point: vertex)
      
      if let index = delaunayTriangleRefArray.index(of: triangleReference) {
        // before appending the new triangles to delaunayTriangleRefArray,  we want to remove the passed triangleReference triangle from it
        // as this containing triangle will be replaced by the subtriangles generated in the next step
        delaunayTriangleRefArray.remove(at: index)
        
        // remove corresponding vertices from delaunayTriangleMeshOrderedVertices render array
        // note that we remove in 'last in, first out' fashion
        delaunayTriangleMeshOrderedVertices.remove(at: (index * 3 + 2))
        delaunayTriangleMeshOrderedVertices.remove(at: (index * 3 + 1))
        delaunayTriangleMeshOrderedVertices.remove(at: (index * 3 + 0))
        
      } // end of if let index
      
      // add triangleRef's to master delaunayTriangleRefArray
      for subTriangleReference in subTriangleArrayRef {
        delaunayTriangleRefArray.append(subTriangleReference)
      } // end of for
      
      // update delaunayTriangleMeshOrderedVertices with subTriangleArrayRef vertices
      delaunayPopulateRenderArray(triangleRefArray: subTriangleArrayRef)
      
    } // end of for triangleReference in triangleRefArray
    
  } // end of func delaunaySubTriangulatePoint
  
  func delaunaySubTriangulatePointOld2(vertex: Vertex2DSimple, triangleRefArray: [TriangleRef]) {

    var subPointCloud2DMetal: [Vertex2DSimple] = [vertex] // initialize array with passed vertex
    for triangleReference in triangleRefArray {
      let v0 = pointCloud2DMetal[triangleReference.index0]
      let v1 = pointCloud2DMetal[triangleReference.index1]
      let v2 = pointCloud2DMetal[triangleReference.index2]
      let vertexArray = [v0,v1,v2]
      subPointCloud2DMetal.append(contentsOf: vertexArray) // append each triangle's vertices
    } // end of for
    
    
    // triangulate points in subPointCloud2DMetal
    let subTriangleArrayRef = Delaunay().triangulate(vertices: subPointCloud2DMetal)
    
    print ("...[delaunaySubTriangulatePoint]: computed \(subTriangleArrayRef.count) triangles")
    
    for triangleReference in triangleRefArray {
      if let index = delaunayTriangleRefArray.index(of: triangleReference) {
        // before appending the new triangles to delaunayTriangleRefArray,  we want to remove the passed triangleReference triangle from it
        // as this containing triangle will be replaced by the subtriangles generated in the next step
        delaunayTriangleRefArray.remove(at: index)
        
        // remove corresponding vertices from delaunayTriangleMeshOrderedVertices render array
        // note that we remove in 'last in, first out' fashion
        delaunayTriangleMeshOrderedVertices.remove(at: (index * 3 + 2))
        delaunayTriangleMeshOrderedVertices.remove(at: (index * 3 + 1))
        delaunayTriangleMeshOrderedVertices.remove(at: (index * 3 + 0))
        
      } // end of if let index
    } // end of for triangleReference in triangleRefArray
    
    // add triangleRef's to master delaunayTriangleRefArray
    for subTriangleReference in subTriangleArrayRef {
      delaunayTriangleRefArray.append(subTriangleReference)
    } // end of for
    
    // update delaunayTriangleMeshOrderedVertices with subTriangleArrayRef vertices
    delaunayPopulateRenderArray(triangleRefArray: subTriangleArrayRef)

  } // end of func delaunaySubTriangulatePoint()
  
  func delaunaySubTriangulatePointOld(vertex: Vertex2DSimple, triangleReference: TriangleRef) {
    
    // extract vertices from triangleRef
    let v0 = pointCloud2DMetal[triangleReference.index0]
    let v1 = pointCloud2DMetal[triangleReference.index1]
    let v2 = pointCloud2DMetal[triangleReference.index2]
    let subPointCloud2DMetal = [v0,v1,v2,vertex]

    // triangulate points in subPointCloud2DMetal
    let subTriangleArrayRef = Delaunay().triangulate(vertices: subPointCloud2DMetal)
    print ("...[delaunaySubTriangulatePoint]: computed \(subTriangleArrayRef.count) triangles")
    
    if let index = delaunayTriangleRefArray.index(of: triangleReference) {
      // before appending the new triangles to delaunayTriangleRefArray,  we want to remove the passed triangleReference triangle from it
      // as this containing triangle will be replaced by the subtriangles generated in the next step
      delaunayTriangleRefArray.remove(at: index)
      
      // remove corresponding vertices from delaunayTriangleMeshOrderedVertices render array
      // note that we remove in 'last in, first out' fashion
      delaunayTriangleMeshOrderedVertices.remove(at: (index * 3 + 2))
      delaunayTriangleMeshOrderedVertices.remove(at: (index * 3 + 1))
      delaunayTriangleMeshOrderedVertices.remove(at: (index * 3 + 0))
      
      // add triangleRef's to master delaunayTriangleRefArray
      for triangleRef in subTriangleArrayRef {
        delaunayTriangleRefArray.append(triangleRef)
      } // end of for
      
      // update delaunayTriangleMeshOrderedVertices with subTriangleArrayRef vertices
      delaunayPopulateRenderArray(triangleRefArray: subTriangleArrayRef)
      
    } // end of if let index

  } // end of func delaunaySubTriangulatePoint()
  
  /*
  func delaunayPopulateRenderArrayOld (vertexCloud2D: [Vertex2DSimple] ) {
    //delaunayTriangleMeshOrderedVertices = [] // empty out ordered 3D array
    //let delaunayTriangleReferences = Delaunay().triangulate(pointCloud2DMetal)
    //delaunayTriangleRefArray = Delaunay().triangulate(vertices: vertexCloud2D)
    print ("...about to draw \(delaunayTriangleRefArray.count) triangles")
    //triangleCount = delaunayTriangleRefArray.count
    for triangleRef in delaunayTriangleRefArray {
      delaunayTriangleMeshOrderedVertices.append(pointCloud3DMetal[triangleRef.index0])
      delaunayTriangleMeshOrderedVertices.append(pointCloud3DMetal[triangleRef.index1])
      delaunayTriangleMeshOrderedVertices.append(pointCloud3DMetal[triangleRef.index2])
    } // end of for
  } // end of func delaunayPopulateRenderArray ()
  */
  /*
  func delaunayPopulateRenderArrayOld () {
    print ("...about to draw \(delaunayTriangleRefArray.count) triangles")
    //triangleCount = delaunayTriangleRefArray.count
    for triangleRef in delaunayTriangleRefArray {
      delaunayTriangleMeshOrderedVertices.append(contentsOf: [
        pointCloud3DMetal[triangleRef.index0],
        pointCloud3DMetal[triangleRef.index1],
        pointCloud3DMetal[triangleRef.index2]
        ])
    } // end of for
  } // end of func delaunayPopulateRenderArray ()
  */
  
  func delaunayPopulateRenderArray (triangleRefArray: [TriangleRef]) {
    //print ("...[delaunayPopulateRenderArray]: about to draw \(triangleRefArray.count) triangles")
    //triangleCount = delaunayTriangleRefArray.count
    for triangleRef in triangleRefArray {
      delaunayTriangleMeshOrderedVertices.append(contentsOf: [
        pointCloud3DMetal[triangleRef.index0],
        pointCloud3DMetal[triangleRef.index1],
        pointCloud3DMetal[triangleRef.index2]
        ])
    } // end of for
  } // end of func delaunayPopulateRenderArray ()
  
  

} // end of class DelaunayTriangulationMetalView
