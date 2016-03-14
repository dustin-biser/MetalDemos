//
//  MetalRenderer.h
//  MetalDemos
//
//  Created by Dustin on 3/10/16.
//  Copyright © 2016 none. All rights reserved.
//

#import <Metal/Metal.h>


@interface MetalRenderDescriptor : NSObject
    @property (nonatomic) id<MTLDevice> device;
    @property (nonatomic) id<MTLLibrary> shaderLibrary;
    @property (nonatomic) int msaaSampleCount;
    @property (nonatomic) MTLPixelFormat colorPixelFormat;
    @property (nonatomic) MTLPixelFormat depthStencilPixelFormat;
    @property (nonatomic) MTLPixelFormat stencilAttachmentPixelFormat;
    @property (nonatomic) int framebufferWidth;
    @property (nonatomic) int framebufferHeight;
    @property (nonatomic) int numBufferedFrames;
    
@end


@interface MetalRenderer : NSObject

    - (instancetype)initWithDescriptor:(MetalRenderDescriptor *)metalRenderDescriptor;

    - (void) reshape:(CGSize)size;

    - (void) render: (id<MTLCommandBuffer>)commandBuffer
        withRenderPassDescriptor: (MTLRenderPassDescriptor *)renderPassDescriptor;

@end
