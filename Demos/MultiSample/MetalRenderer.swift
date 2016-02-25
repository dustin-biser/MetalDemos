//
//  MetalRenderer.swift
//  MetalSwift
//
//  Created by Dustin on 1/23/16.
//  Copyright © 2016 none. All rights reserved.
//

import Metal
import MetalKit

struct MetalRenderDescriptor {
    var device : MTLDevice
    var shaderLibrary: MTLLibrary
    var sampleCount : Int
    var colorPixelFormat : MTLPixelFormat
    var depthStencilPixelFormat : MTLPixelFormat
    var stencilAttachmentPixelFormat : MTLPixelFormat
    var framebufferWidth : Int
    var framebufferHeight : Int
}

class MetalRenderer {

    var device : MTLDevice
    var shaderLibrary: MTLLibrary
    var sampleCount : Int
    var colorPixelFormat : MTLPixelFormat
    var depthStencilPixelFormat : MTLPixelFormat
    var stencilAttachmentPixelFormat : MTLPixelFormat
    var framebufferWidth : Int
    var framebufferHeight : Int
    
    var pipelineState : MTLRenderPipelineState!   = nil
    var depthStencilState : MTLDepthStencilState! = nil
   
    var vertexBuffer : MTLBuffer!                 = nil
    var indexBuffer : MTLBuffer!                  = nil
    var numIndices : Int = 0
    
    
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
        
        self.uploadVertexData()
        
        self.prepareDepthStencilState()
        
        self.preparePipelineState()
    }

    
    //-----------------------------------------------------------------------------------
    private func uploadVertexData() {
        
        let triangleVertices : [Float32] = [
            -0.5, -0.32,  0.0,
             0.5, -0.3,  0.0,
             0.4,  0.4,  0.0
        ]
        
        //-- Upload vertex positions to vertexBuffer:
        vertexBuffer = device.newBufferWithBytes(
            triangleVertices,
            length: triangleVertices.count * sizeof(Float32),
            options: .OptionCPUCacheModeDefault
        )
        vertexBuffer.label = "VertexBuffer"
        
        
        let indices : [UInt16] = [
            0,1, 1,2, 2,0
        ]
        numIndices = indices.count
        
        
        //-- Upload indices to indexBuffer:
        indexBuffer = device.newBufferWithBytes(
            indices,
            length: indices.count * sizeof(UInt16),
            options: .OptionCPUCacheModeDefault
        )
        
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
        
        
        
        //-- Render Pipeline Descriptor:
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Forward Render Pipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.sampleCount = sampleCount
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = depthStencilPixelFormat
        
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
                    width: Double(framebufferWidth),
                    height: Double(framebufferHeight),
                    znear: 0,
                    zfar: 1)
            )
            renderEncoder.setDepthStencilState(depthStencilState)
            
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
            
            renderEncoder.drawIndexedPrimitives(
                .Line,
                indexCount: numIndices,
                indexType: .UInt16,
                indexBuffer: indexBuffer,
                indexBufferOffset: 0)
        
            renderEncoder.endEncoding()
            renderEncoder.popDebugGroup()
    }

    //-----------------------------------------------------------------------------------
    /// Main rendering method
    func render(
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0
        )
        renderPassDescriptor.depthAttachment.clearDepth = 1.0
        
        
        encodeRenderCommandsInto(commandBuffer, using: renderPassDescriptor)
        
    }

} // end class MetalRenderer