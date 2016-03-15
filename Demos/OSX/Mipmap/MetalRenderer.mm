//
//  MetalRenderer.m
//  MetalDemos
//
//  Created by Dustin on 3/10/16.
//  Copyright © 2016 none. All rights reserved.
//

#import "MetalRenderer.h"
#import "ShaderResourceIndices.h"

#import <vector>



@implementation MetalRenderDescriptor : NSObject


@end



// Private methods
@interface MetalRenderer ()
    - (void) prepareDepthStencilState;

    - (void) preparePipelineState;

    - (id<MTLFunction>) newFunctionWithName:(NSString *)functionName;

    - (void) uploadDataToVertexBuffer;

    - (void) encodeRenderCommandInto:(id<MTLCommandBuffer>)commandBuffer
            withRenderPassDescriptor:(MTLRenderPassDescriptor *)renderPassDescriptor;
@end



std::vector<float> TriangleVertices = {
    -0.5, -0.5,  0.0,
     0.5, -0.5,  0.0,
     0.0,  0.5,  0.0
};



@implementation MetalRenderer {
    id<MTLDevice> _device;
    
    id<MTLLibrary> _shaderLibrary;
    
    int _msaaSampleCount;
    
    MTLPixelFormat _colorPixelFormat;
    MTLPixelFormat _depthStencilPixelFormat;
    MTLPixelFormat _stencilAttachmentPixelFormat;
    
    int _framebufferWidth;
    int _framebufferHeight;
    
    int _numBufferedFrames;
    
    id<MTLRenderPipelineState> _renderPipelineState;
    id<MTLDepthStencilState> _depthStencilState;
    
    id<MTLBuffer> _vertexBuffer;
}

    //-----------------------------------------------------------------------------------
    - (instancetype)initWithDescriptor:(MetalRenderDescriptor *)metalRenderDescriptor {
        if(self = [super init]) {
            _device = metalRenderDescriptor.device;
            _shaderLibrary = metalRenderDescriptor.shaderLibrary;
            _msaaSampleCount = metalRenderDescriptor.msaaSampleCount;
            _colorPixelFormat = metalRenderDescriptor.colorPixelFormat;
            _depthStencilPixelFormat = metalRenderDescriptor.depthStencilPixelFormat;
            _stencilAttachmentPixelFormat = metalRenderDescriptor.stencilAttachmentPixelFormat;
            _framebufferWidth = metalRenderDescriptor.framebufferWidth;
            _framebufferHeight = metalRenderDescriptor.framebufferHeight;
            _numBufferedFrames = metalRenderDescriptor.numBufferedFrames;
            
            [self prepareDepthStencilState];
            [self preparePipelineState];
            [self uploadDataToVertexBuffer];
            
        }
        return self;
    }


    //-----------------------------------------------------------------------------------
    - (id<MTLFunction>) newFunctionWithName:(NSString *)functionName {
        id<MTLFunction> function = [_shaderLibrary newFunctionWithName:functionName];
        if(function == nil) {
            NSLog(@"Error retrieving shader function: %@", functionName);
            exit(0);
        }
        
        return function;
    }

    //-----------------------------------------------------------------------------------
    - (void) preparePipelineState {
        id<MTLFunction> vertexFunction = [self newFunctionWithName:@"vertexFunction"];
        id<MTLFunction> fragmentFunction = [self newFunctionWithName:@"fragmentFunction"];
        
        MTLVertexDescriptor * vertexDescriptor = [[MTLVertexDescriptor alloc] init];
        
        //-- Position vertex attribute description:
        auto positionAttribute = vertexDescriptor.attributes[PositionAttribute];
        positionAttribute.format = MTLVertexFormatFloat3;
        positionAttribute.offset = 0;
        positionAttribute.bufferIndex = VertexBufferIndex;
        
        //-- Vertex buffer layout description:
        auto vertexLayoutDescriptor = vertexDescriptor.layouts[VertexBufferIndex];
        vertexLayoutDescriptor.stride = sizeof(Float32) * 3;
        vertexLayoutDescriptor.stepRate = 1;
        vertexLayoutDescriptor.stepFunction = MTLVertexStepFunctionPerVertex;
        
        auto renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        renderPipelineDescriptor.label = @"Render Pipeline";
        renderPipelineDescriptor.vertexFunction = vertexFunction;
        renderPipelineDescriptor.fragmentFunction = fragmentFunction;
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor;
        renderPipelineDescriptor.sampleCount = _msaaSampleCount;
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = _colorPixelFormat;
        renderPipelineDescriptor.depthAttachmentPixelFormat = _depthStencilPixelFormat;
        renderPipelineDescriptor.stencilAttachmentPixelFormat = _depthStencilPixelFormat;
        
        NSError * errors = nil;
        _renderPipelineState =
            [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                    error:&errors];
        if(errors != nil) {
            NSLog(@"Error creating MTLRenderPipelineState");
            NSLog(@"Error msg: %@", errors.userInfo);
            exit(0);
        }
    }

    //-----------------------------------------------------------------------------------
    - (void) prepareDepthStencilState {
        auto depthStencilDescriptor = [[MTLDepthStencilDescriptor alloc] init];
        depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
        depthStencilDescriptor.depthWriteEnabled = true;
        _depthStencilState =
            [_device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
    }

    //-----------------------------------------------------------------------------------
    - (void) uploadDataToVertexBuffer {
        auto numBytes = TriangleVertices.size() * sizeof(Float32);
        _vertexBuffer =
            [_device newBufferWithBytes: TriangleVertices.data()
                                 length: numBytes
                                options: MTLResourceOptionCPUCacheModeDefault];
        _vertexBuffer.label = @"Triangle Vertices";
    }

    //-----------------------------------------------------------------------------------
    - (void) reshape:(CGSize)size {
        _framebufferWidth = (int)size.width;
        _framebufferHeight = (int)size.height;
    }

    //-----------------------------------------------------------------------------------
    - (void) encodeRenderCommandInto:(id<MTLCommandBuffer>)commandBuffer
            withRenderPassDescriptor:(MTLRenderPassDescriptor *)renderPassDescriptor {
        
        renderPassDescriptor.colorAttachments[0].clearColor =
            MTLClearColorMake(0.2, 0.2, 0.2, 1.0);
        
        renderPassDescriptor.depthAttachment.clearDepth = 1.0;
        
        auto renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        
        [renderEncoder pushDebugGroup:@"Triangle"];
        
        [renderEncoder setViewport:
             MTLViewport{0, 0,
                         double(_framebufferWidth),
                         double(_framebufferHeight),
                         0, 1}
         ];
        
        [renderEncoder setDepthStencilState: _depthStencilState];
        [renderEncoder setRenderPipelineState: _renderPipelineState];
        
        [renderEncoder setVertexBuffer: _vertexBuffer
                                offset: 0
                               atIndex: 0];
        
        [renderEncoder drawPrimitives: MTLPrimitiveTypeTriangle
                          vertexStart: 0
                          vertexCount: 3];
        
        [renderEncoder endEncoding];
        [renderEncoder popDebugGroup];
    }

    //-----------------------------------------------------------------------------------
    /// Main rendering method
    - (void) render: (id<MTLCommandBuffer>)commandBuffer
        withRenderPassDescriptor: (MTLRenderPassDescriptor *)renderPassDescriptor {

        [self encodeRenderCommandInto: commandBuffer
             withRenderPassDescriptor: renderPassDescriptor];
    }

@end // MetalRenderer
