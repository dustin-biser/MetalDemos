//
//  MipmapRenderer.h
//  MetalDemos
//
//  Created by Dustin on 3/10/16.
//  Copyright © 2016 none. All rights reserved.
//

#import <Metal/Metal.h>
#import <ModelIO/ModelIO.h>

// Forward declaration
class Camera;


@interface MipmapRenderDescriptor : NSObject
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


@interface MipmapRenderer : NSObject

    - (instancetype)initWithDescriptor:(MipmapRenderDescriptor *)metalRenderDescriptor;

    - (void) reshape:(CGSize)size;

    - (void) render: (id<MTLCommandBuffer>)commandBuffer
                renderPassDescriptor: (MTLRenderPassDescriptor *)renderPassDescriptor
                camera: (const Camera &)camera;

   - (void) generateMipmapLevels: (id<MTLCommandBuffer>)commandBuffer;

@end
