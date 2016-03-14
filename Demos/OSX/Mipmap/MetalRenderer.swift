//
//  MetalRenderer.swift
//
//  Created by Dustin on 1/23/16.
//  Copyright © 2016 none. All rights reserved.
//

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
    
    var vertexBuffer : MTLBuffer! = nil
    var frameUniformBuffers : [MTLBuffer!]! = nil
    var currentFrame : Int = 0
    
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
        
        self.frameUniformBuffers = [MTLBuffer!](count: numBufferedFrames, repeatedValue: nil)
        
        self.prepareDepthStencilState()
        self.preparePipelineState()
        
        self.allocateUniformBuffers()
        self.setFrameUniforms()
        
        self.allocateVertexBufferData()
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
        let modelMatrix = matrix_identity_float4x4;
        
        // Projection Matrix:
        let width = Float(self.framebufferWidth)
        let height = Float(self.framebufferHeight)
        let aspect = width / height
        let fovy = Float(65.0) * (Float(M_PI) / Float(180.0))
        let projectionMatrix = matrix_from_perspective_fov_aspectLH(fovy, aspect,
            Float(0.1), Float(100))
        
        let viewMatrix = matrix_from_translation(0.0, 0.0, 2.0)
        var modelView = matrix_multiply(viewMatrix, modelMatrix)
        let normalMatrix = sub_matrix_float3x3(&modelView)
        
        var frameUniforms = FrameUniforms(
            modelMatrix: modelMatrix,
            viewMatrix: viewMatrix,
            projectionMatrix: projectionMatrix,
            normalMatrix: normalMatrix
        )
        
        memcpy(frameUniformBuffers[currentFrame].contents(), &frameUniforms,
            strideof(FrameUniforms))
        
        currentFrame = (currentFrame + 1) % frameUniformBuffers.count
    }
    
    //-----------------------------------------------------------------------------------
    private func allocateVertexBufferData() {
        // Use RAII to load data into objLaoder.
        // Then copy data to vertex buffer.  Once scope exits, the objLoader
        // object will be destroyed and all memory freed.
        let objLoader = ObjLoader(fileName: "textured_plane.obj")
        
        
//        let numBytes = CubeVertexData.count * sizeof(Float32)
//        vertexBuffer = device.newBufferWithBytes (
//            CubeVertexData,
//            length: numBytes,
//            options: .OptionCPUCacheModeDefault
//        )
//        vertexBuffer.label = "CubeVertexData"
    }
    
    //-----------------------------------------------------------------------------------
    func reshape(size: CGSize) {
        self.framebufferWidth = Int(size.width)
        self.framebufferHeight = Int(size.height)
    }
    
    //-----------------------------------------------------------------------------------
    private func preparePipelineState() {
        
        guard let vertexFunction = shaderLibrary.newFunctionWithName("vertexFunction")
            else {
                print("Error retrieving vertex function.")
                fatalError()
        }
        
        guard let fragmentFunction = shaderLibrary.newFunctionWithName("fragmentFunction")
            else {
                print("Error retrieving fragment function.")
                fatalError()
        }
    
        // Create a vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        
        //-- Vertex Positions, attribute description:
        let positionAttributeDescriptor = vertexDescriptor.attributes[PositionAttribute]
        positionAttributeDescriptor.format = MTLVertexFormat.Float3
        positionAttributeDescriptor.offset = 0
        positionAttributeDescriptor.bufferIndex = VertexBufferIndex
        
        //-- Vertex Normals, attribute description:
        let normalAttributeDescriptor = vertexDescriptor.attributes[NormalAttribute]
        normalAttributeDescriptor.format = MTLVertexFormat.Float3
        normalAttributeDescriptor.offset = sizeof(Float32) * 3
        normalAttributeDescriptor.bufferIndex = VertexBufferIndex
        
        //-- Vertex buffer layout description:
        let vertexBufferLayoutDescriptor = vertexDescriptor.layouts[VertexBufferIndex]
        vertexBufferLayoutDescriptor.stride = sizeof(Float32) * 6
        vertexBufferLayoutDescriptor.stepRate = 1
        vertexBufferLayoutDescriptor.stepFunction = MTLVertexStepFunction.PerVertex
        
        
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
    private func encodeRenderCommandsInto (
        commandBuffer: MTLCommandBuffer,
        using renderPassDescriptor: MTLRenderPassDescriptor
    ) {
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
                width: Double(self.framebufferWidth),
                height: Double(self.framebufferHeight),
                znear: 0,
                zfar: 1)
        )
        renderEncoder.setDepthStencilState(depthStencilState)
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setVertexBuffer(
                vertexBuffer,
                offset: 0,
                atIndex: VertexBufferIndex
        )
        
        renderEncoder.setVertexBuffer(
                frameUniformBuffers[currentFrame],
                offset: 0,
                atIndex: FrameUniformBufferIndex
        )
        
        renderEncoder.drawPrimitives(
                MTLPrimitiveType.Triangle,
                vertexStart: 0,
                vertexCount: 36
        )
        renderEncoder.endEncoding()
        renderEncoder.popDebugGroup()
    }
    
    //-----------------------------------------------------------------------------------
    /// Main rendering method
    func render(
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
            setFrameUniforms()
            
            encodeRenderCommandsInto(commandBuffer, using: renderPassDescriptor)
        
            currentFrame = (currentFrame + 1) % self.numBufferedFrames
    }
    
}
