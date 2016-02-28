//
//  MultiSampleDemo.swift
//  MetalSwift
//
//  Created by Dustin on 2/22/16.
//  Copyright © 2016 none. All rights reserved.
//

import AppKit
import MetalKit


class MultiSampleDemo : DemoBaseOSX {
    
    var metalRenderer : MetalRenderer! = nil
        
    //-----------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupMTKView()
        
        self.setMultiBufferMode(.SingleBuffer)
        
        let metalRenderDescriptor = MetalRenderDescriptor(
            device: device,
            shaderLibrary: defaultShaderLibrary,
            sampleCount: mtkView.sampleCount,
            colorPixelFormat: mtkView.colorPixelFormat,
            depthStencilPixelFormat: mtkView.depthStencilPixelFormat,
            stencilAttachmentPixelFormat: mtkView.depthStencilPixelFormat,
            framebufferWidth: Int(mtkView.drawableSize.width),
            framebufferHeight: Int(mtkView.drawableSize.height),
            numBufferedFrames: self.numBufferedFrames
        )
        metalRenderer = MetalRenderer(descriptor: metalRenderDescriptor)
    }
    
    //-----------------------------------------------------------------------------------
    private func setupMTKView() {
        mtkView.sampleCount = 4
        mtkView.colorPixelFormat = MTLPixelFormat.BGRA8Unorm
        mtkView.depthStencilPixelFormat = MTLPixelFormat.Depth32Float_Stencil8
        mtkView.framebufferOnly = false
        
        // Manually set the view's color buffer size.
        mtkView.autoResizeDrawable = false
        mtkView.drawableSize = CGSize(width: 128, height: 128)
        
        // Turn off linear filtering of the view's Metal Layer during magnification.
        let caLayer = mtkView.layer
        caLayer?.magnificationFilter = kCAFilterNearest
    }
    
    //-----------------------------------------------------------------------------------
    override func viewSizeChanged (
            view: MTKView,
            newSize: CGSize
    ) {
    
    }
    
    //-----------------------------------------------------------------------------------
    override func draw(commandBuffer : MTLCommandBuffer) {
        metalRenderer.render(
            commandBuffer,
            renderPassDescriptor: mtkView.currentRenderPassDescriptor!
        )
    }
    
}
