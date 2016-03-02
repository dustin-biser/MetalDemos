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
        
        print("Press keys 1, 2, 4, or 8 for number of MSAA samples")
    }
    
    //-----------------------------------------------------------------------------------
    private func setupMTKView() {
        mtkView.sampleCount = 1
        mtkView.colorPixelFormat = MTLPixelFormat.BGRA8Unorm
        mtkView.depthStencilPixelFormat = MTLPixelFormat.Depth32Float_Stencil8
        mtkView.framebufferOnly = false
        
        // Manually set the view's color buffer size.
        mtkView.autoResizeDrawable = false
        
        let aspect = mtkView.drawableSize.width / mtkView.drawableSize.height
        let viewHeight : CGFloat = 64.0
        let viewWidth = viewHeight * aspect
        mtkView.drawableSize = CGSize(width: viewWidth, height: viewHeight)
        
        // Turn off linear filtering of the view's Metal Layer during magnification.
        let caLayer = mtkView.layer!
        caLayer.magnificationFilter = kCAFilterNearest
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
    
    //-----------------------------------------------------------------------------------
    override func keyDown(theEvent: NSEvent) {
        switch theEvent.characters! {
        case "1":
            mtkView.sampleCount = 1
            break
        case "2":
            mtkView.sampleCount = 2
            break
        case "4":
            mtkView.sampleCount = 4
            break
        case "8":
            mtkView.sampleCount = 8
            break
        default:
            break
            
        }
        
        mtkView.window?.title = "MultiSample Demo (\(mtkView.sampleCount) MSAA samples)"
        
        metalRenderer.setSampleCount(mtkView.sampleCount)
    }
    
}
