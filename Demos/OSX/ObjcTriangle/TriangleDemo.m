//
//  TriangleDemo.m
//  MetalDemos
//
//  Created by Dustin on 3/10/16.
//  Copyright © 2016 none. All rights reserved.
//

#import "MetalDemoCommon.h"
#import "TriangleDemo.h"
#import "MetalRenderer.h"


// Private methods
@interface TriangleDemo ()
    
    - (void) setupMetalView;

@end


@implementation TriangleDemo {
@private
    MetalRenderer * _metalRenderer;
    
}

    //-----------------------------------------------------------------------------------
    - override (void)viewWillAppear {
        [super viewWillAppear];
        [self setupMetalView];
        
        // TripleBuffer rendering of frames.
        _numBufferedFrames = 3;
        
        MetalRenderDescriptor * metalRenderDescriptor = [[MetalRenderDescriptor alloc] init];
        metalRenderDescriptor.device = _device;
        metalRenderDescriptor.shaderLibrary = _defaultShaderLibrary;
        metalRenderDescriptor.msaaSampleCount = (int)_metalView.sampleCount;
        metalRenderDescriptor.colorPixelFormat = _metalView.colorPixelFormat;
        metalRenderDescriptor.depthStencilPixelFormat= _metalView.depthStencilPixelFormat;
        metalRenderDescriptor.stencilAttachmentPixelFormat = _metalView.depthStencilPixelFormat;
        metalRenderDescriptor.framebufferWidth = _metalView.drawableSize.width;
        metalRenderDescriptor.framebufferHeight = _metalView.drawableSize.height;
        metalRenderDescriptor.numBufferedFrames = _numBufferedFrames;
        
        _metalRenderer = [[MetalRenderer alloc] initWithDescriptor: metalRenderDescriptor];
        
    }


    //-----------------------------------------------------------------------------------
    - (void) setupMetalView {
        _metalView.sampleCount = 8;
        _metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        _metalView.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
        _metalView.framebufferOnly = true;
    }

    //-----------------------------------------------------------------------------------
    - override (void) viewSizeChanged:(MTKView *)view
                    newSize:(CGSize)size {
    
        [_metalRenderer reshape: size];
    }

    //-----------------------------------------------------------------------------------
    - (void) draw:(id<MTLCommandBuffer>)commandBuffer {
        [_metalRenderer render: commandBuffer
           withRenderPassDescriptor: _metalView.currentRenderPassDescriptor];
    }

@end // TriangleDemo
