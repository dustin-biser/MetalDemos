//
//  TriangleDemo.m
//  MetalDemos
//
//  Created by Dustin on 3/10/16.
//  Copyright © 2016 none. All rights reserved.
//

#import "TriangleDemo.h"
#import "DemoBase+protected.h"
#import "MetalRenderer.h"


// Private members
@interface TriangleDemo () {
@private
    MetalRenderer * metalRenderer;
    
}
    - (void) setupMetalView;

@end



@implementation TriangleDemo

    //-----------------------------------------------------------------------------------
    - (void)viewWillAppear {
        [super viewWillAppear];
        [self setupMetalView];
        
        // TripleBuffer rendering of frames.
        _numBufferedFrames = 3;
        
//        let metalRenderDescriptor = MetalRenderDescriptor(
//            device: device,
//            shaderLibrary: defaultShaderLibrary,
//            sampleCount: mtkView.sampleCount,
//            colorPixelFormat: mtkView.colorPixelFormat,
//            depthStencilPixelFormat: mtkView.depthStencilPixelFormat,
//            stencilAttachmentPixelFormat: mtkView.depthStencilPixelFormat,
//            framebufferWidth: Int(mtkView.drawableSize.width),
//            framebufferHeight: Int(mtkView.drawableSize.height),
//            numBufferedFrames: self.numBufferedFrames
//        )
//        metalRenderer = MetalRenderer(descriptor: metalRenderDescriptor)
        
    }


    //-----------------------------------------------------------------------------------
    - (void) setupMetalView {
        _metalView.sampleCount = 8;
        _metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
        _metalView.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
        _metalView.framebufferOnly = true;
    }

@end // TriangleDemo
