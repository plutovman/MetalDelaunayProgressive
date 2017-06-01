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
  
  var delaunayTriangleArrayRef: [TriangleRef]! // stores triangles as index references to pointCloudMetal array
  var triangleCount: Int = 0
  let fpsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 20))
  var frameCounter: Int = 0
  var frameStartTime = CFAbsoluteTimeGetCurrent()
  
  
  weak var MetalViewDelegate: DelaunayTriangulationMetalViewDelegate?
  
  ////////////////////
  init(frame: CGRect) {
    
    super.init(frame: frame, device: MTLCreateSystemDefaultDevice())
    initializeMetalArrays() // initialize arrays
    setupMetalRenderPipeline() // one-time metal initialization
    setupVerticesViewBBox() // set up initial vertices
    delaunayCompute() // compute resulting triangles
    
    
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Override methods
  override func draw(_ rect: CGRect) {
    
    step() // needed to update frame counter
    autoreleasepool {
      // if we want to generate triangles via the view's internal timer, we want to
      // call a generation routine (such as setupTrianglesRandom() AND, we must take care
      // to set the view's .enableSetNeedsDisplay = true  and .isPaused = true
      //setupTrianglesRandom(numTriangles: 10000)
      //setupTrianglesDelaunay(vertexCount: 1000)
      
      // regardless of whether we are updating manually via user event (such as touchesBegan)
      // or we use the view's internal timer, we must always update state via renderTriangles()
      renderTriangles()
    }
    
  }
  
  // MARK: - Metal methods
  
  func step() {
    frameCounter += 1
    if frameCounter == 100
    {
      let frametime = (CFAbsoluteTimeGetCurrent() - frameStartTime) / 100
      MetalViewDelegate?.fpsUpdate(fps: Int(1 / frametime), triangleCount: triangleCount) // let the delegate know of the frame update
      print ("...frametime: \((Int(1/frametime)))")
      frameStartTime = CFAbsoluteTimeGetCurrent() // reset start time
      frameCounter = 0 // reset counter
    }
  } // end of func step()
  
  func setupMetalRenderPipeline(){
    
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
    
  } // end of setupMetalRenderPipeline
  
  
  func initializeMetalArrays() {
    pointCloud3DMetal = []
    pointCloud2DMetal = []
    

  } // end of func initializeMetalArrays()
  
  
  // overall note about vertices.  we WANT to work with Vertex3DColor from the get go.
  // ho
  
  // the design strategy regarding vertex handling is as follows:
  // 1. from view's touch, convert touch coordinates (in device space) to Vertex3DColor coordinates (in metal space)
  // 2. store Vertex3DColor vertices in master pointCloud3DMetal array
  // 3. buld an array of [Vertex2DSimple] from [Vertex3DColor] in previous step . Remember to store index placement in new field!
  // 3. delaunayCompute() returns an aray of [TriangleRef] that refer to Vertex3DColor indices
  // 4. renderTriangles() must build a local [Vertex3DColor] array by stepping through triangles' indices in step 3
  
  // vertexAppend() needs to:
  // 1. append vertex to pointCloud3DMetal [Vertex3DColor] array
  // 2. find out the triangle that contains the new point
  // 3. delete triangle ref from [TriangleRef]
  // 4. create a new [Vertex2DSimple] array containing index references to the new point coord, plus refs to the coordinates of the triangle just deleted
  // 5. run delaunayCompute() on that array which will return an updated [TriangleRef]
  
  func setupVerticesViewBBox() {
    
    let v0 = Vertex3DColor(x: -1.0, y: 1.0, z: 0.0, r: 1.0, g: 0.0, b: 0.0, a: 1.0) // ul
    let v1 = Vertex3DColor(x: 1.0, y: 1.0, z: 0.0, r: 0.0, g: 1.0, b: 0.0, a: 1.0) // ur
    let v2 = Vertex3DColor(x: -1.0, y: -1.0, z: 0.0, r: 0.0, g: 0.0, b: 1.0, a: 1.0) // ll
    let v3 = Vertex3DColor(x: 1.0, y: -1.0, z: 0.0, r: 1.0, g: 1.0, b: 0.0, a: 1.0) // lr
    /*
    pointCloud3DMetal.append(v0)
    pointCloud3DMetal.append(v1)
    pointCloud3DMetal.append(v2)
    pointCloud3DMetal.append(v3)
    */
    
    // temporary troubleshooting
    pointCloud2DMetal.append(Vertex2DSimple(x: CGFloat(v0.x), y: CGFloat(v0.y), index: 0))
    pointCloud2DMetal.append(Vertex2DSimple(x: CGFloat(v1.x), y: CGFloat(v1.y), index: 1))
    pointCloud2DMetal.append(Vertex2DSimple(x: CGFloat(v2.x), y: CGFloat(v2.y), index: 2))
    pointCloud2DMetal.append(Vertex2DSimple(x: CGFloat(v3.x), y: CGFloat(v3.y), index: 3))
    
  } // end of func setupVerticesViewBBox()
  
  func setupVerticesRandom(numVertices: Int) {
    
    for _ in 0 ... numVertices {
      let x = CGFloat.random(-1.0, 1.0) * self.bounds.size.width
      let y = CGFloat.random(-1.0, 1.0) * self.bounds.size.height
      
      let v = Vertex2DSimple(x: x, y: y, index: pointCloud2DMetal.count)
      
      pointCloud2DMetal.append(v)
    } // end of for
    
  } // end of func setupVerticesRandom()
  
  func delaunayCompute () {
    let delaunayTriangles = Delaunay().triangulate(pointCloud2DMetal)
    
    for triangle in delaunayTriangles {
      
      let x1 = Float(triangle.vertex1.x)
      let x2 = Float(triangle.vertex2.x)
      let x3 = Float(triangle.vertex3.x)
      
      let y1 = Float(triangle.vertex1.y)
      let y2 = Float(triangle.vertex2.y)
      let y3 = Float(triangle.vertex3.y)
      
      let v0 = Vertex3DColor(x: x1, y: y1, z: 0.0, r: 1.0, g: 0.0, b: 0.0, a: 1.0)
      let v1 = Vertex3DColor(x: x2, y: y2, z: 0.0, r: 0.0, g: 1.0, b: 0.0, a: 1.0)
      let v2 = Vertex3DColor(x: x3, y: y3, z: 0.0, r: 0.0, g: 0.0, b: 1.0, a: 1.0)
      
      pointCloud3DMetal.append(v0)
      pointCloud3DMetal.append(v1)
      pointCloud3DMetal.append(v2)
      
    } // end of for
  } // end of func delaunayCompute ()
  
  func renderTriangles(){
    // 6. Set buffer size of objects to be drawn
    //let dataSize = vertexCount * MemoryLayout<Vertex3DColor>.size // size of the vertex data in bytes
    let dataSize = pointCloud3DMetal.count * MemoryLayout<Vertex3DColor>.stride // apple recommendation
    let vertexBuffer: MTLBuffer = device!.makeBuffer(bytes: pointCloud3DMetal, length: dataSize, options: []) // create a new buffer on the GPU
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
      renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: pointCloud3DMetal.count)
      
      ///////////renderCommandEncoder?.popDebugGroup()
      renderCommandEncoder?.endEncoding() // finalize renderEncoder set up
      
      commandBuffer?.present(self.currentDrawable!) // needed to make sure the new texture is presented as soon as the drawing completes
      
      // 7b. Render to pipeline
      commandBuffer?.commit() // commit and send task to gpu
      
    } // end of if renderPassDescriptor
    
  }// end of func renderTriangles()

} // end of class DelaunayTriangulationMetalView
