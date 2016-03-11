//
//  MetalRenderer.m
//  MetalDemos
//
//  Created by Dustin on 3/10/16.
//  Copyright © 2016 none. All rights reserved.
//

#import "MetalRenderer.h"



@implementation MetalRenderDescriptor : NSObject


@end



// Private methods
@interface MetalRenderer ()
    - (void) prepareDepthStencilState;
    - (void) preparePipelineState;
@end


@implementation MetalRenderer {
    id<MTLDevice> _device;
    id<MTLLibrary> _shaderLibrary;
    int _sampleCount;
    MTLPixelFormat _colorPixelFormat;
    MTLPixelFormat _depthStencilPixelFormat;
    MTLPixelFormat _stencilAttachmentPixelFormat;
    int _framebufferWidth;
    int _framebufferHeight;
    int _numBufferedFrames;
    
}

    //-----------------------------------------------------------------------------------
    - (instancetype)initWithDescriptor:(MetalRenderDescriptor *)metalRenderDescriptor {
        if(self = [super init]) {
            _device = metalRenderDescriptor.device;
            _shaderLibrary = metalRenderDescriptor.shaderLibrary;
            _sampleCount = metalRenderDescriptor.sampleCount;
            _colorPixelFormat = metalRenderDescriptor.colorPixelFormat;
            _depthStencilPixelFormat = metalRenderDescriptor.depthStencilPixelFormat;
            _stencilAttachmentPixelFormat = metalRenderDescriptor.stencilAttachmentPixelFormat;
            _framebufferWidth = metalRenderDescriptor.framebufferWidth;
            _framebufferHeight = metalRenderDescriptor.framebufferHeight;
            _numBufferedFrames = metalRenderDescriptor.numBufferedFrames;
            
            [self prepareDepthStencilState];
            [self preparePipelineState];
        }
        
        
        return self;
    }

    //-----------------------------------------------------------------------------------
    - (void) preparePipelineState {
        id<MTLFunction> vertexFunction =
            [_shaderLibrary newFunctionWithName:@"vertexFunction"];
        if(vertexFunction == nil) {
            NSLog(@"Error retrieving vertex function");
            exit(0);
        }
    }

    //-----------------------------------------------------------------------------------
    - (void) prepareDepthStencilState {
        
    }

    //-----------------------------------------------------------------------------------
    - (void) reshape:(CGSize)size {
        _framebufferWidth = (int)size.width;
        _framebufferHeight = (int)size.height;
    }

@end // MetalRenderer
