//
//  ViewController.swift
//  MetalSwift
//
//  Created by Dustin on 12/30/15.
//  Copyright © 2015 none. All rights reserved.
//

import AppKit
import Metal
import MetalKit

private let numPreflightFrames = 3

private let TriangleVertices : [Float32] = [
    -0.5, -0.5,  0.0,
     0.5, -0.5,  0.0,
     0.0,  0.5,  0.0
]

class MetalViewController: NSViewController {
    
    @IBOutlet weak var mtkView: MTKView!

    var device : MTLDevice!                        = nil
    var commandQueue : MTLCommandQueue!            = nil
    var defaultShaderLibrary : MTLLibrary!         = nil
    var vertexBuffer : MTLBuffer!                  = nil
    var pipelineState : MTLRenderPipelineState!    = nil
    var depthStencilState : MTLDepthStencilState!  = nil
    
    lazy var inflightSemaphore = dispatch_semaphore_create(numPreflightFrames)
    
    
    //-----------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupMetal()
        self.setupView()
        self.preparePipelineState()
        self.prepareDepthStencilState()
    }

    //-----------------------------------------------------------------------------------
    private func setupView() {
        mtkView.delegate = self
        mtkView.device = device
        mtkView.sampleCount = 4
        mtkView.colorPixelFormat = MTLPixelFormat.BGRA8Unorm
        mtkView.depthStencilPixelFormat = MTLPixelFormat.Depth32Float_Stencil8
        mtkView.preferredFramesPerSecond = 30
        mtkView.framebufferOnly = true
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
        
        //-- Position vertex attribute description:
        let positionIndex = IndexForVertexAttribute.Positions.rawValue
        let positionAttributeDescriptor = vertexDescriptor.attributes[positionIndex]
        positionAttributeDescriptor.format = MTLVertexFormat.Float3
        positionAttributeDescriptor.offset = 0
        positionAttributeDescriptor.bufferIndex = IndexForBuffer.VertexBuffer.rawValue
        
        //-- Vertex buffer layout description:
        let vertexBufferIndex = IndexForBuffer.VertexBuffer.rawValue
        let vertexBufferLayoutDescriptor = vertexDescriptor.layouts[vertexBufferIndex]
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
    private func reshape() {
        
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
    private func render() {
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
    
} // end class MetalViewController


extension MetalViewController : MTKViewDelegate {

    //-----------------------------------------------------------------------------------
    // Called whenever the drawableSize of the view will change
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        self.reshape()
    }

    //-----------------------------------------------------------------------------------
    // Called on the delegate when it is asked to render into the view
    func drawInMTKView(view: MTKView) {
        autoreleasepool {
            self.render()
        }
        
    }

}

