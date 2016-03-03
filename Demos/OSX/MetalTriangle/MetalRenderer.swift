//
//  MetalRenderer.swift
//  MetalSwift
//
//  Created by Dustin on 1/23/16.
//  Copyright © 2016 none. All rights reserved.
//

import Metal
import MetalKit


private let TriangleVertices : [Float32] = [
    -0.5, -0.5,  0.0,
     0.5, -0.5,  0.0,
     0.0,  0.5,  0.0
]

struct MetalRenderDescriptor {
    var device : MTLDevice
    var shaderLibrary: MTLLibrary
    var sampleCount : Int
    var colorPixelFormat : MTLPixelFormat
    var depthStencilPixelFormat : MTLPixelFormat
    var stencilAttachmentPixelFormat : MTLPixelFormat
    var framebufferWidth : Int
    var framebufferHeight : Int
    var numBufferedFrames : Int
}

class MetalRenderer {

    private var device : MTLDevice
    private var shaderLibrary: MTLLibrary
    private var sampleCount : Int
    private var colorPixelFormat : MTLPixelFormat
    private var depthStencilPixelFormat : MTLPixelFormat
    private var stencilAttachmentPixelFormat : MTLPixelFormat
    private var framebufferWidth : Int
    private var framebufferHeight : Int
    private var numBufferedFrames : Int
    
    private var pipelineState : MTLRenderPipelineState!   = nil
    private var depthStencilState : MTLDepthStencilState! = nil
    
    private var vertexBuffer : MTLBuffer! = nil
    
    //-----------------------------------------------------------------------------------
    init(descriptor : MetalRenderDescriptor) {
        self.device = descriptor.device
        self.shaderLibrary = descriptor.shaderLibrary
        self.sampleCount = descriptor.sampleCount
        self.colorPixelFormat = descriptor.colorPixelFormat
        self.depthStencilPixelFormat = descriptor.depthStencilPixelFormat
        self.stencilAttachmentPixelFormat = descriptor.stencilAttachmentPixelFormat
        self.framebufferWidth = descriptor.framebufferWidth
        self.framebufferHeight = descriptor.framebufferHeight
        self.numBufferedFrames = descriptor.numBufferedFrames
        
        self.prepareDepthStencilState()
        self.preparePipelineState()
    }

    //-----------------------------------------------------------------------------------
    private func preparePipelineState() {
        
        guard let vertexFunction = shaderLibrary.newFunctionWithName("vertexFunction")
            else {
                fatalError("Error retrieving vertex function.")
        }
        
        guard let fragmentFunction = shaderLibrary.newFunctionWithName("fragmentFunction")
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
        pipelineDescriptor.sampleCount = self.sampleCount
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = self.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = self.depthStencilPixelFormat
        
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
        self.framebufferWidth = Int(size.width)
        self.framebufferHeight = Int(size.height)
    }

    //-----------------------------------------------------------------------------------
    private func encodeRenderCommandsInto (
        commandBuffer: MTLCommandBuffer,
        using renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        
        renderPassDescriptor.colorAttachments[0].clearColor =
                MTLClearColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        
        renderPassDescriptor.depthAttachment.clearDepth = 1.0
        
        let renderEncoder =
                commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        
        renderEncoder.pushDebugGroup("Triangle")
        renderEncoder.setViewport(
            MTLViewport(
                originX: 0,
                originY: 0,
                width: Double(self.framebufferWidth),
                height: Double(self.framebufferHeight),
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
    /// Main rendering method
    func render(
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
            encodeRenderCommandsInto(commandBuffer, using: renderPassDescriptor)
    }

} // end class MetalRenderer