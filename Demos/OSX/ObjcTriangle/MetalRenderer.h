//
//  MetalRenderer.h
//  MetalDemos
//
//  Created by Dustin on 3/10/16.
//  Copyright © 2016 none. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>


@interface MetalRenderDescriptor
    @property (nonatomic) id<MTLDevice> device;
    @property (nonatomic) id<MTLLibrary> shaderLibrary;
    @property (nonatomic) int sampleCount;
    @property (nonatomic) MTLPixelFormat colorPixelFormat;
    @property (nonatomic) MTLPixelFormat depthStencilPixelFormat;
    @property (nonatomic) MTLPixelFormat stencilAttachmentPixelFormat;
    @property (nonatomic) int framebufferWidth;
    @property (nonatomic) int framebufferHeight;
    @property (nonatomic) int numBufferedFrames;
    
@end


@interface MetalRenderer : NSObject

@end
