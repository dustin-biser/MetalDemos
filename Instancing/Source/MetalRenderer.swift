//
//  MetalRenderer.swift
//
//  Created by Dustin on 1/23/16.
//  Copyright © 2016 none. All rights reserved.
//

import MetalKit


private let kWidth  : Float32 = 0.5;
private let kHeight : Float32 = 0.5;
private let kDepth  : Float32 = 0.5;

private let CubeVertexData : [Float32] = [
//           Postions                  Normals
     kWidth, -kHeight,  kDepth,     0.0, -1.0,  0.0,
    -kWidth, -kHeight,  kDepth,     0.0, -1.0,  0.0,
    -kWidth, -kHeight, -kDepth,     0.0, -1.0,  0.0,
     kWidth, -kHeight, -kDepth,     0.0, -1.0,  0.0,
     kWidth, -kHeight,  kDepth,     0.0, -1.0,  0.0,
    -kWidth, -kHeight, -kDepth,     0.0, -1.0,  0.0,
    
     kWidth,  kHeight,  kDepth,     1.0,  0.0,  0.0,
     kWidth, -kHeight,  kDepth,     1.0,  0.0,  0.0,
     kWidth, -kHeight, -kDepth,     1.0,  0.0,  0.0,
     kWidth,  kHeight, -kDepth,     1.0,  0.0,  0.0,
     kWidth,  kHeight,  kDepth,     1.0,  0.0,  0.0,
     kWidth, -kHeight, -kDepth,     1.0,  0.0,  0.0,
    
    -kWidth,  kHeight,  kDepth,     0.0,  1.0,  0.0,
     kWidth,  kHeight,  kDepth,     0.0,  1.0,  0.0,
     kWidth,  kHeight, -kDepth,     0.0,  1.0,  0.0,
    -kWidth,  kHeight, -kDepth,     0.0,  1.0,  0.0,
    -kWidth,  kHeight,  kDepth,     0.0,  1.0,  0.0,
     kWidth,  kHeight, -kDepth,     0.0,  1.0,  0.0,
    
    -kWidth, -kHeight,  kDepth,    -1.0,  0.0,  0.0,
    -kWidth,  kHeight,  kDepth,    -1.0,  0.0,  0.0,
    -kWidth,  kHeight, -kDepth,    -1.0,  0.0,  0.0,
    -kWidth, -kHeight, -kDepth,    -1.0,  0.0,  0.0,
    -kWidth, -kHeight,  kDepth,    -1.0,  0.0,  0.0,
    -kWidth,  kHeight, -kDepth,    -1.0,  0.0,  0.0,
    
     kWidth,  kHeight,  kDepth,     0.0,  0.0,  1.0,
    -kWidth,  kHeight,  kDepth,     0.0,  0.0,  1.0,
    -kWidth, -kHeight,  kDepth,     0.0,  0.0,  1.0,
    -kWidth, -kHeight,  kDepth,     0.0,  0.0,  1.0,
     kWidth, -kHeight,  kDepth,     0.0,  0.0,  1.0,
     kWidth,  kHeight,  kDepth,     0.0,  0.0,  1.0,
    
     kWidth, -kHeight, -kDepth,     0.0,  0.0, -1.0,
    -kWidth, -kHeight, -kDepth,     0.0,  0.0, -1.0,
    -kWidth,  kHeight, -kDepth,     0.0,  0.0, -1.0,
     kWidth,  kHeight, -kDepth,     0.0,  0.0, -1.0,
     kWidth, -kHeight, -kDepth,     0.0,  0.0, -1.0,
    -kWidth,  kHeight, -kDepth,     0.0,  0.0, -1.0
]

private let numInflightCommands = 3



class MetalRenderer {

    unowned var mtkView : MTKView
    
    var device : MTLDevice!                        = nil
    var commandQueue : MTLCommandQueue!            = nil
    var defaultShaderLibrary : MTLLibrary!         = nil
    var vertexBuffer : MTLBuffer!                  = nil
    var pipelineState : MTLRenderPipelineState!    = nil
    var depthStencilState : MTLDepthStencilState!  = nil
    
    var inflightSemaphore = dispatch_semaphore_create(numInflightCommands)
    
    var frameUniformBuffers = [MTLBuffer!](count: numInflightCommands, repeatedValue: nil)
    var currentUniformBufferIndex : Int = 0
    
    var rotationAngle : Float = 0.0
    let rotationDelta : Float = 0.01
    
    
    //-----------------------------------------------------------------------------------
    init(withMTKView view:MTKView) {
        mtkView = view
        
        self.setupMetal()
        self.setupView()
        
        self.prepareDepthStencilState()
        self.preparePipelineState()
        
        self.allocateUniformBuffers()
        self.setFrameUniforms()
        
        self.allocateVertexBufferData()
    }
    
    //-----------------------------------------------------------------------------------
    private func setupMetal() {
        device = MTLCreateSystemDefaultDevice()
        if device == nil {
            print("Error creating default MTLDevice.")
            fatalError()
        }
        
        commandQueue = device.newCommandQueue()
        
        defaultShaderLibrary = device.newDefaultLibrary()
    }

    //-----------------------------------------------------------------------------------
    private func setupView() {
        mtkView.device = device
        mtkView.sampleCount = 4
        mtkView.colorPixelFormat = MTLPixelFormat.BGRA8Unorm
        mtkView.depthStencilPixelFormat = MTLPixelFormat.Depth32Float_Stencil8
        mtkView.preferredFramesPerSecond = 60
        mtkView.framebufferOnly = true
    }
    
    //-----------------------------------------------------------------------------------
    private func allocateUniformBuffers() {
        for index in frameUniformBuffers.indices {
            frameUniformBuffers[index] = device.newBufferWithLength (
                    strideof(FrameUniforms),
                    options: .CPUCacheModeDefaultCache
            )
        }
    }
    
    //-----------------------------------------------------------------------------------
    private func setFrameUniforms() {
        rotationAngle += rotationDelta
        var modelMatrix = matrix_from_rotation(rotationAngle, 1, 1, 0)
        modelMatrix = matrix_multiply(matrix_from_translation(0.0, 0.0, 2.0), modelMatrix)
        
        // Projection Matrix:
        let width = Float(self.mtkView.bounds.size.width)
        let height = Float(self.mtkView.bounds.size.height)
        let aspect = width / height
        let fovy = Float(65.0) * (Float(M_PI) / Float(180.0))
        let projectionMatrix = matrix_from_perspective_fov_aspectLH(fovy, aspect,
            Float(0.1), Float(100))
        
        let viewMatrix = matrix_identity_float4x4
        var modelView = matrix_multiply(viewMatrix, modelMatrix)
        let normalMatrix = sub_matrix_float3x3(&modelView)
        
        var frameUniforms = FrameUniforms()
        frameUniforms.modelMatrix = modelMatrix
        frameUniforms.viewMatrix = viewMatrix
        frameUniforms.projectionMatrix = projectionMatrix
        frameUniforms.normalMatrix = normalMatrix
        
        memcpy(frameUniformBuffers[currentUniformBufferIndex].contents(), &frameUniforms,
            strideof(FrameUniforms))
        
        currentUniformBufferIndex = (currentUniformBufferIndex + 1) % frameUniformBuffers.count
    }
    
    //-----------------------------------------------------------------------------------
    private func allocateVertexBufferData() {
        let numBytes = CubeVertexData.count * sizeof(Float32)
        vertexBuffer = device.newBufferWithBytes (
            CubeVertexData,
            length: numBytes,
            options: .OptionCPUCacheModeDefault
        )
        vertexBuffer.label = "CubeVertexData"
    }
    
    //-----------------------------------------------------------------------------------
    func reshape(size: CGSize) {
//        let width = Float(self.view.bounds.size.width)
//        let height = Float(self.view.bounds.size.height)
//        let aspect = width / height
//        let fovy = Float(65.0) * (Float(M_PI) / Float(180.0))
//        let projectionMatrix = matrix_from_perspective_fov_aspectLH(fovy, aspect,
//            Float(0.1), Float(100))
        
        //TODO: Need to copy projectionMatrix to frameUniformBuffer for use in next frame.
    }
    
    //-----------------------------------------------------------------------------------
    private func preparePipelineState() {
        
        guard let vertexFunction = defaultShaderLibrary.newFunctionWithName("vertexFunction")
            else {
                print("Error retrieving vertex function.")
                fatalError()
        }
        
        guard let fragmentFunction = defaultShaderLibrary.newFunctionWithName("fragmentFunction")
            else {
                print("Error retrieving fragment function.")
                fatalError()
        }
    
        // Create a vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        
        //-- Vertex Positions, attribute description:
        let positionAttributeDescriptor = vertexDescriptor.attributes[PositionAttributeIndex.rawValue]
        positionAttributeDescriptor.format = MTLVertexFormat.Float3
        positionAttributeDescriptor.offset = 0
        positionAttributeDescriptor.bufferIndex = VertexBufferIndex.rawValue
        
        //-- Vertex Normals, attribute description:
        let normalAttributeDescriptor = vertexDescriptor.attributes[NormalAttributeIndex.rawValue]
        normalAttributeDescriptor.format = MTLVertexFormat.Float3
        normalAttributeDescriptor.offset = sizeof(Float32) * 3
        normalAttributeDescriptor.bufferIndex = VertexBufferIndex.rawValue
        
        //-- Vertex buffer layout description:
        let vertexBufferLayoutDescriptor = vertexDescriptor.layouts[VertexBufferIndex.rawValue]
        vertexBufferLayoutDescriptor.stride = sizeof(Float32) * 6
        vertexBufferLayoutDescriptor.stepRate = 1
        vertexBufferLayoutDescriptor.stepFunction = MTLVertexStepFunction.PerVertex
        
        
        //-- Render Pipeline Descriptor:
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Forward Render Pipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.sampleCount = mtkView.sampleCount
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        
        // Create our render pipeline state for reuse
        pipelineState = try! device.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
    }
    
    //-----------------------------------------------------------------------------------
    private func prepareDepthStencilState() {
        let depthStencilDecriptor = MTLDepthStencilDescriptor()
        depthStencilDecriptor.depthCompareFunction = MTLCompareFunction.Less
        depthStencilDecriptor.depthWriteEnabled = true
        depthStencilState = device.newDepthStencilStateWithDescriptor(depthStencilDecriptor)
    }
    
    //-----------------------------------------------------------------------------------
    private func encodeRenderCommandsInto (commandBuffer: MTLCommandBuffer) {
        // Get the current MTLRenderPassDescriptor and set it's color and depth
        // clear values:
        let renderPassDescriptor = mtkView.currentRenderPassDescriptor!
        renderPassDescriptor.colorAttachments[0].clearColor =
                MTLClearColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        renderPassDescriptor.depthAttachment.clearDepth = 1.0
        
        let renderEncoder =
            commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        
        renderEncoder.pushDebugGroup("Cube")
        renderEncoder.setViewport(
            MTLViewport(
                originX: 0,
                originY: 0,
                width: Double(mtkView.drawableSize.width),
                height: Double(mtkView.drawableSize.height),
                znear: 0,
                zfar: 1)
        )
        renderEncoder.setDepthStencilState(depthStencilState)
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setVertexBuffer(
                vertexBuffer,
                offset: 0,
                atIndex: VertexBufferIndex.rawValue
        )
        
        renderEncoder.setVertexBuffer(
                frameUniformBuffers[currentUniformBufferIndex],
                offset: 0,
                atIndex: FrameUniformBufferIndex.rawValue
        )
        
        // TODO - change this to drawPrimitives(_ primitiveType: MTLPrimitiveType,
        //        vertexStart vertexStart: Int,
        //        vertexCount vertexCount: Int,
        //        instanceCount instanceCount: Int)
        renderEncoder.drawPrimitives(
                MTLPrimitiveType.Triangle,
                vertexStart: 0,
                vertexCount: 36
        )
        renderEncoder.endEncoding()
        renderEncoder.popDebugGroup()
    }
    
    //-----------------------------------------------------------------------------------
    /// Main render method
    func render() {
        for var i = 0; i < numInflightCommands; ++i {
            // Allow the renderer to preflight frames on the CPU (using a semapore as
            // a guard) and commit them to the GPU.  This semaphore will get signaled
            // once the GPU completes a frame's work via addCompletedHandler callback
            // below, signifying the CPU can go ahead and prepare another frame.
            dispatch_semaphore_wait(inflightSemaphore, DISPATCH_TIME_FOREVER);
            
            setFrameUniforms()
            
            let commandBuffer = commandQueue.commandBuffer()
            
            encodeRenderCommandsInto(commandBuffer)
            
            commandBuffer.presentDrawable(mtkView.currentDrawable!)
            
            
            // Once GPU has completed executing the commands wihin this buffer, signal
            // the semaphore and allow the CPU to proceed in constructing the next frame.
            commandBuffer.addCompletedHandler() { mtlCommandbuffer in
                let didWake = dispatch_semaphore_signal(self.inflightSemaphore)
                if didWake != 0 {
                    print("Thread woken.")
                }
            }
            
            // Push command buffer to GPU for execution.
            commandBuffer.commit()
        }
    }
    
}
