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


private let kWidth  : Float32 = 0.75;
private let kHeight : Float32 = 0.75;
private let kDepth  : Float32 = 0.75;

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


class MetalViewController: NSViewController {
    
    @IBOutlet weak var mtkView: MTKView!

    var device : MTLDevice!                        = nil
    var commandQueue : MTLCommandQueue!            = nil
    var defaultShaderLibrary : MTLLibrary!         = nil
    var vertexBuffer : MTLBuffer!                  = nil
    var pipelineState : MTLRenderPipelineState!    = nil
    var depthStencilState : MTLDepthStencilState!  = nil
    
    var inflightSemaphore = dispatch_semaphore_create(numPreflightFrames)
    
    var frameUniformBuffer : MTLBuffer! = nil
    var viewMatrix       : matrix_float4x4 = matrix_identity_float4x4
    var projectionMatrix : matrix_float4x4 = matrix_identity_float4x4
    
    
    //-----------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupMetal()
        self.setupView()
        self.setFrameUniforms()
        self.uploadVertexBufferData()
        self.preparePipelineState()
        self.prepareDepthStencilState()
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
        mtkView.delegate = self
        mtkView.device = device
        mtkView.sampleCount = 4
        mtkView.colorPixelFormat = MTLPixelFormat.BGRA8Unorm
        mtkView.depthStencilPixelFormat = MTLPixelFormat.Depth32Float_Stencil8
        mtkView.preferredFramesPerSecond = 30
        mtkView.framebufferOnly = true
    }
    
    //-----------------------------------------------------------------------------------
    private func setFrameUniforms() {
        
        frameUniformBuffer = device.newBufferWithLength (
                sizeof(FrameUniforms),
                options: .CPUCacheModeDefaultCache
        )
        
        var frameUniforms = FrameUniforms()
        frameUniforms.modelMatrix = matrix_identity_float4x4
        frameUniforms.viewMatrix = matrix_from_rotation(0.2, 1, 1, 0)
        frameUniforms.projectionMatrix = self.projectionMatrix
        frameUniforms.normalMatrix = matrix_identity_float4x4
        
        memcpy(frameUniformBuffer.contents(), &frameUniforms, sizeof(FrameUniforms))
    }
    
    //-----------------------------------------------------------------------------------
    private func uploadVertexBufferData() {
        let numBytes = CubeVertexData.count * sizeof(Float32)
        vertexBuffer = device.newBufferWithBytes (
            CubeVertexData,
            length: numBytes,
            options: .OptionCPUCacheModeDefault
        )
        vertexBuffer.label = "CubeVertexData"
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
    private func reshape() {
        let width = Float(self.view.bounds.size.width)
        let height = Float(self.view.bounds.size.height)
        let aspect = width / height
        let fovy = Float(65.0) * (Float(M_PI) / Float(180.0))
        projectionMatrix = matrix_from_perspective_fov_aspectLH(fovy, aspect,
            Float(0.1), Float(100))
    }
    
    //-----------------------------------------------------------------------------------
    private func encodeRenderCommandsInto (
        commandBuffer: MTLCommandBuffer,
        using renderPassDescriptor: MTLRenderPassDescriptor
    ) {
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
                frameUniformBuffer,
                offset: 0,
                atIndex: FrameUniformBufferIndex.rawValue
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

} // end extension MetalViewController

