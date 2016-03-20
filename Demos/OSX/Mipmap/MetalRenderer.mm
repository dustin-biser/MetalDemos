//
//  MetalRenderer.mm
//  MetalDemos
//
//  Created by Dustin on 3/10/16.
//  Copyright © 2016 none. All rights reserved.
//

#import "MetalRenderer.h"
#import "ShaderResourceIndices.h"
#import "ShaderUniforms.h"
#import "MatrixTransforms.h"
#import "Camera.hpp"

#import <MetalKit/MetalKit.h>

#import <glm/glm.hpp>
#import <glm/gtc/matrix_transform.hpp>
#import <glm/gtx/io.hpp>
using namespace glm;

#import <iostream>
#import <vector>


//---------------------------------------------------------------------------------------
static glm::mat4 matrix_float4x4_to_glm_mat4(const matrix_float4x4 & mat) {
    return glm::mat4 {
        vec4{mat.columns[0][0], mat.columns[0][1], mat.columns[0][2], mat.columns[0][3]},
        vec4{mat.columns[1][0], mat.columns[1][1], mat.columns[1][2], mat.columns[1][3]},
        vec4{mat.columns[2][0], mat.columns[2][1], mat.columns[2][2], mat.columns[2][3]},
        vec4{mat.columns[3][0], mat.columns[3][1], mat.columns[3][2], mat.columns[3][3]},
    };
    
}

//---------------------------------------------------------------------------------------
static matrix_float4x4 glm_mat4_to_matrix_float4x4(const glm::mat4 & mat) {
    return matrix_float4x4 {
        .columns[0] = {mat[0][0], mat[0][1], mat[0][2], mat[0][3]},
        .columns[1] = {mat[1][0], mat[1][1], mat[1][2], mat[1][3]},
        .columns[2] = {mat[2][0], mat[2][1], mat[2][2], mat[2][3]},
        .columns[3] = {mat[3][0], mat[3][1], mat[3][2], mat[3][3]},
    };
}

//---------------------------------------------------------------------------------------
static matrix_float3x3 glm_mat3_to_matrix_float3x3(const glm::mat3 & mat) {
    return matrix_float3x3 {
        .columns[0] = {mat[0][0], mat[0][1], mat[0][2]},
        .columns[1] = {mat[1][0], mat[1][1], mat[1][2]},
        .columns[2] = {mat[2][0], mat[2][1], mat[2][2]}
    };
}


//---------------------------------------------------------------------------------------
@implementation MetalRenderDescriptor : NSObject


@end




//---------------------------------------------------------------------------------------
// Private methods
@interface MetalRenderer ()
    - (void) prepareDepthStencilState;

    - (void) preparePipelineState;

    - (id<MTLFunction>) newFunctionWithName:(NSString *)functionName;

    - (void) uploadDataToVertexBuffer;

    - (void) setFrameUniforms: (const Camera &)camera;

    - (void) allocateFrameUniformBuffers;

    - (void) encodeRenderCommandInto:(id<MTLCommandBuffer>)commandBuffer
            withRenderPassDescriptor:(MTLRenderPassDescriptor *)renderPassDescriptor;
@end




//---------------------------------------------------------------------------------------
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
    MTLVertexDescriptor * _vertexDescriptor;
    MTKMesh * _planeMesh;
    
    NSMutableArray<id<MTLBuffer>> * _frameUniformBuffers;
    int _currentFrame;
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
            
            _currentFrame = 0;
            
            [self prepareDepthStencilState];
            
            [self preparePipelineState];
            
            [self uploadDataToVertexBuffer];
            
            [self allocateFrameUniformBuffers];
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
        
        //-- Normal vertex attribute description:
        auto normalAttribute = vertexDescriptor.attributes[NormalAttribute];
        normalAttribute.format = MTLVertexFormatFloat3;
        normalAttribute.offset = sizeof(Float32) * 3;
        normalAttribute.bufferIndex = VertexBufferIndex;
        
        //-- Texture coordinate vertex attribute description:
        auto textureCoordAttribute = vertexDescriptor.attributes[TextureCoordinateAttribute];
        textureCoordAttribute.format = MTLVertexFormatFloat2;
        textureCoordAttribute.offset = sizeof(Float32) * 6;
        textureCoordAttribute.bufferIndex = VertexBufferIndex;
        
        //-- Vertex buffer layout description:
        auto vertexLayoutDescriptor = vertexDescriptor.layouts[VertexBufferIndex];
        vertexLayoutDescriptor.stride = sizeof(Float32) * 8;
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
        
        // Set depth compare function to LessEqual in order to do Depth Clamping
        // so that no fragments are clipped outside view frustum
        depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLessEqual;
        
        depthStencilDescriptor.depthWriteEnabled = true;
        _depthStencilState =
            [_device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
    }

    //-----------------------------------------------------------------------------------
    - (void) uploadDataToVertexBuffer {
        // Create a MDLVertexDescriptor from an existing MTLVertexDescriptor
        MDLVertexDescriptor * mdlVertexDescriptor =
                MTKModelIOVertexDescriptorFromMetal(_vertexDescriptor);
        
        // Specify vertex attribute type for each attribute location slot.
        auto mdlAttributes = mdlVertexDescriptor.attributes;
        mdlAttributes[PositionAttribute].name = MDLVertexAttributePosition;
        mdlAttributes[NormalAttribute].name = MDLVertexAttributeNormal;
        mdlAttributes[TextureCoordinateAttribute].name =
                MDLVertexAttributeTextureCoordinate;
        
        MTKMeshBufferAllocator * bufferAllocator =
                [[MTKMeshBufferAllocator alloc] initWithDevice:_device];
        
        NSURL * assetURL = [[NSBundle mainBundle]
            URLForResource: @"Assets/Meshes/textured_plane.obj"
             withExtension: nil
        ];
        
        NSError * errors = nil;
        MDLAsset * asset =
            [[MDLAsset alloc] initWithURL: assetURL
                         vertexDescriptor: mdlVertexDescriptor
                          bufferAllocator: bufferAllocator
                         preserveTopology: NO
                                    error: &errors];
        if(errors) {
            NSLog(@"Error loading assset: %@.\n With Error: %@", assetURL, errors);
        }
        
        
        NSArray<MTKMesh * > * mtkMeshArray =
                [MTKMesh newMeshesFromAsset: asset
                                     device: _device
                               sourceMeshes: nil
                                      error: &errors];
        if(errors) {
            NSLog(@"Error loading assset: %@.\n With Error: %@", assetURL, errors);
        }
        
        
        _planeMesh = mtkMeshArray[0];
        
    }

    //-----------------------------------------------------------------------------------
    - (void) allocateFrameUniformBuffers {
        _frameUniformBuffers = [[NSMutableArray alloc] initWithCapacity:_numBufferedFrames];
        for(int i(0); i < _numBufferedFrames; ++i) {
            _frameUniformBuffers[i] = [_device newBufferWithLength: sizeof(FrameUniforms)
                                          options: MTLResourceOptionCPUCacheModeDefault];
            
        }
    }


    //-----------------------------------------------------------------------------------
    - (void) setFrameUniforms: (const Camera &)camera {
    
        // Projection Matrix:
        float width = float(_framebufferWidth);
        float height = float(_framebufferHeight);
        float aspect = width / height;
        float fovy = 65.0f * (M_PI / 180.0f);
        glm::mat4 projectionMatrix = glm::perspective(fovy, aspect, 0.1f, 100.0f);
        
        
        
        
        glm::mat4 modelMatrix = glm::mat4();
        glm::mat4 viewMatrix = camera.viewMatrix();
        glm::mat4 modelView = viewMatrix * modelMatrix;
        glm::mat3 normalMatrix = glm::transpose(glm::inverse(glm::mat3(modelView)));
        
        FrameUniforms frameUniforms = FrameUniforms();
        frameUniforms.modelMatrix = glm_mat4_to_matrix_float4x4(modelMatrix);
        frameUniforms.viewMatrix = glm_mat4_to_matrix_float4x4(viewMatrix);
        frameUniforms.projectionMatrix = glm_mat4_to_matrix_float4x4(projectionMatrix);
        frameUniforms.normalMatrix = glm_mat3_to_matrix_float3x3(normalMatrix);
        
        memcpy([_frameUniformBuffers[_currentFrame] contents],
               &frameUniforms, sizeof(FrameUniforms));
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
        
        
        [renderEncoder pushDebugGroup:@"Ground Plane"];
        
        [renderEncoder setViewport:
             MTLViewport{0.0, 0.0,
                         double(_framebufferWidth),
                         double(_framebufferHeight),
                         0.0, 1.0}
         ];
        
        
        // Clamp depth values so fragments are visible outside frustum near/far planes.
        [renderEncoder setDepthClipMode: MTLDepthClipModeClamp];
        
        
        [renderEncoder setDepthStencilState: _depthStencilState];
        [renderEncoder setRenderPipelineState: _renderPipelineState];
        
        
        for(MTKMeshBuffer * vertexBuffer in _planeMesh.vertexBuffers) {
            [renderEncoder setVertexBuffer: vertexBuffer.buffer
                                    offset: vertexBuffer.offset
                                   atIndex: VertexBufferIndex];
        }
        
        
        [renderEncoder setVertexBuffer: _frameUniformBuffers[_currentFrame]
                                offset: 0
                               atIndex: FrameUniformBufferIndex];
    
        
        
        for(MTKSubmesh * subMesh in _planeMesh.submeshes) {
            [renderEncoder drawIndexedPrimitives: MTLPrimitiveTypeTriangle
                                      indexCount: subMesh.indexCount
                                       indexType: subMesh.indexType
                                     indexBuffer: subMesh.indexBuffer.buffer
                               indexBufferOffset: subMesh.indexBuffer.offset
             ];
        }
        
        [renderEncoder endEncoding];
        [renderEncoder popDebugGroup];
    }

    //-----------------------------------------------------------------------------------
    /// Main rendering method
    - (void) render: (id<MTLCommandBuffer>)commandBuffer
                 renderPassDescriptor: (MTLRenderPassDescriptor *)renderPassDescriptor
                 camera: (const Camera &)camera {

        [self setFrameUniforms:camera];

        [self encodeRenderCommandInto: commandBuffer
             withRenderPassDescriptor: renderPassDescriptor];
        
        _currentFrame = (_currentFrame + 1) % _numBufferedFrames;
    }

@end // MetalRenderer
