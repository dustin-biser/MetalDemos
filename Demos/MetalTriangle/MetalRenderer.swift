//
//  MetalRenderer.swift
//  MetalSwift
//
//  Created by Dustin on 1/23/16.
//  Copyright © 2016 none. All rights reserved.
//

import Metal
import MetalKit

private let numPreflightFrames = 3

private let TriangleVertices : [Float32] = [
    -0.5, -0.5,  0.0,
     0.5, -0.5,  0.0,
     0.0,  0.5,  0.0
]


class MetalRenderer {

    var device : MTLDevice!                        = nil
    var commandQueue : MTLCommandQueue!            = nil
    var defaultShaderLibrary : MTLLibrary!         = nil
    var vertexBuffer : MTLBuffer!                  = nil
    var pipelineState : MTLRenderPipelineState!    = nil
    var depthStencilState : MTLDepthStencilState!  = nil
    
    var inflightSemaphore = dispatch_semaphore_create(numPreflightFrames)
    
    unowned var mtkView : MTKView
    
    //-----------------------------------------------------------------------------------
    init(withMTKView view:MTKView) {
        mtkView = view
        
        
        self.setupMetal()
        self.setupView()
        self.prepareDepthStencilState()
        self.preparePipelineState()
    }
    
    //-----------------------------------------------------------------------------------
    private func setupMetal() {
        device = MTLCreateSystemDefaultDevice()
        if (device == nil) {
            fatalError("Error creating default MTLDevice.")
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
    private func preparePipelineState() {
        
        guard let vertexFunction = defaultShaderLibrary.newFunctionWithName("vertexFunction")
            else {
                fatalError("Error retrieving vertex function.")
        }
        
        guard let fragmentFunction = defaultShaderLibrary.newFunctionWithName("fragmentFunction")
            else {
                fatalError("Error retrieving fragment function.")
        }
        
        // Create a vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        
        //-- Position vertex attribute description:
        let positionAttributeDescriptor = vertexDescriptor.attributes[PositionAttribute]
        positionAttributeDescriptor.format = MTLVertexFormat.Float3
        positionAttributeDescriptor.offset = 0
        positionAttributeDescriptor.bufferIndex = VertexBufferIndex
        
        //-- Vertex buffer layout description:
        let vertexBufferLayoutDescriptor = vertexDescriptor.layouts[VertexBufferIndex]
        vertexBufferLayoutDescriptor.stride = sizeof(Float32) * 3
        vertexBufferLayoutDescriptor.stepRate = 1
        vertexBufferLayoutDescriptor.stepFunction = MTLVertexStepFunction.PerVertex
        
        
        //-- Setup vertex buffer:
        let numBytes = TriangleVertices.count * sizeof(Float32)
        vertexBuffer = device.newBufferWithBytes(TriangleVertices,
            length: numBytes,
            options: .OptionCPUCacheModeDefault)
        vertexBuffer.label = "TriangleVertices"
        
        
        
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
    func reshape(size: CGSize) {
        
    }

    //-----------------------------------------------------------------------------------
    private func encodeRenderCommandsInto (
        commandBuffer: MTLCommandBuffer,
        using renderPassDescriptor: MTLRenderPassDescriptor
    ) {
            let renderEncoder =
            commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
            
            renderEncoder.pushDebugGroup("Triangle")
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
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
            
            renderEncoder.drawPrimitives(MTLPrimitiveType.Triangle, vertexStart: 0, vertexCount: 3)
            renderEncoder.endEncoding()
            renderEncoder.popDebugGroup()
    }

    //-----------------------------------------------------------------------------------
    /// Main render method
    func render() {
        // Allow the renderer to preflight frames on the CPU (using a semapore as
        // a guard) and commit them to the GPU.  This semaphore will get signaled
        // once the GPU completes a frame's work via addCompletedHandler callback
        // below, signifying the CPU can go ahead and prepare another frame.
        dispatch_semaphore_wait(inflightSemaphore, DISPATCH_TIME_FOREVER);
        
        //--> Update any constant buffers here.
        
        let commandBuffer = commandQueue.commandBuffer()
        
        let renderPassDescriptor = mtkView.currentRenderPassDescriptor!
        renderPassDescriptor.colorAttachments[0].clearColor =
            MTLClearColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        renderPassDescriptor.depthAttachment.clearDepth = 1.0
        
        
        encodeRenderCommandsInto(commandBuffer, using: renderPassDescriptor)
        
        commandBuffer.presentDrawable(mtkView.currentDrawable!)
        
        
        // Once GPU has completed executing the commands wihin this buffer, signal
        // the semaphore and allow the CPU to proceed in constructing the next frame.
        commandBuffer.addCompletedHandler() { buffer in
            dispatch_semaphore_signal(self.inflightSemaphore)
        }
        
        // Push command buffer to GPU for execution.
        commandBuffer.commit()
    }

} // end class MetalRenderer