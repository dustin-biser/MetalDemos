//
//  DeferredShadingRenderer.mm
//  MetalDemos
//
//  Created by Dustin on 3/10/16.
//  Copyright © 2016 none. All rights reserved.
//

#import "DeferredShadingRenderer.h"
#import "ShaderResourceIndices.h"
#import "ShaderUniforms.h"
#import "MatrixTransforms.h"
#import "Camera.hpp"
#import "GlmSimdConversion.hpp"
#import "Mesh.h"

#import <MetalKit/MetalKit.h>
#import <ModelIO/ModelIO.h>

#import <glm/glm.hpp>
#import <glm/gtc/matrix_transform.hpp>
using namespace glm;




@implementation DeferredShadingRenderDescriptor : NSObject


@end




// Private methods
@interface DeferredShadingRenderer ()
    - (void) prepareDepthStencilState;

    - (void) preparePipelineState;

    - (id<MTLFunction>) newShaderFunctionWithName:(NSString *)functionName;

    - (void) loadMeshAssets;

    - (void) loadTextureAssets;

    - (void) setFrameUniforms: (const Camera &)camera;

    - (void) allocateFrameUniformBuffers;

    - (void) encodeRenderCommandInto:(id<MTLCommandBuffer>)commandBuffer
            withRenderPassDescriptor:(MTLRenderPassDescriptor *)renderPassDescriptor;

@end




@implementation DeferredShadingRenderer {
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
    
    // City Mesh
    Mesh * _cityMesh;
    id<MTLTexture> _cityTexture;
    
    // Plane mesh
    Mesh * _groundPlaneMesh;
    id<MTLTexture> _groundPlaneTexture;
    
    NSMutableArray<id<MTLBuffer>> * _frameUniformBuffers;
    int _currentFrame;
}

    //-----------------------------------------------------------------------------------
    - (instancetype)initWithDescriptor:(DeferredShadingRenderDescriptor *)metalRenderDescriptor {
        self = [super init];
        if(!self) {
            return nil;
        }
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
        
        [self loadMeshAssets];
        
        [self allocateFrameUniformBuffers];
        
        [self loadTextureAssets];
        
        
        return self;
    }


    //-----------------------------------------------------------------------------------
    - (id<MTLFunction>) newShaderFunctionWithName:(NSString *)functionName {
        id<MTLFunction> function = [_shaderLibrary newFunctionWithName:functionName];
        if(function == nil) {
            NSLog(@"Error retrieving shader function: %@", functionName);
            exit(0);
        }
        
        return function;
    }

    //-----------------------------------------------------------------------------------
    - (void) preparePipelineState {
        id<MTLFunction> vertexFunction = [self newShaderFunctionWithName:@"vertexFunction"];
        id<MTLFunction> fragmentFunction = [self newShaderFunctionWithName:@"fragmentFunction"];
        
        _vertexDescriptor = [[MTLVertexDescriptor alloc] init];
        
        //-- Describe vertex data as interleaved attributes:
        {
            //-- Position vertex attribute description:
            auto positionAttribute = _vertexDescriptor.attributes[Position];
            positionAttribute.format = MTLVertexFormatFloat3;
            positionAttribute.offset = 0;
            positionAttribute.bufferIndex = VertexBufferIndex;
            
            //-- Normal vertex attribute description:
            auto normalAttribute = _vertexDescriptor.attributes[Normal];
            normalAttribute.format = MTLVertexFormatFloat3;
            normalAttribute.offset = sizeof(Float32) * 3;
            normalAttribute.bufferIndex = VertexBufferIndex;
            
            //-- Texture coordinate vertex attribute description:
            auto textureCoordAttribute = _vertexDescriptor.attributes[TextureCoordinate];
            textureCoordAttribute.format = MTLVertexFormatFloat2;
            textureCoordAttribute.offset = sizeof(Float32) * 6;
            textureCoordAttribute.bufferIndex = VertexBufferIndex;
            
            //-- Vertex buffer layout description:
            auto vertexLayoutDescriptor = _vertexDescriptor.layouts[VertexBufferIndex];
            vertexLayoutDescriptor.stride = sizeof(Float32) * 8;
            vertexLayoutDescriptor.stepRate = 1;
            vertexLayoutDescriptor.stepFunction = MTLVertexStepFunctionPerVertex;
        }
        
        auto renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        renderPipelineDescriptor.label = @"Render Pipeline";
        renderPipelineDescriptor.vertexFunction = vertexFunction;
        renderPipelineDescriptor.fragmentFunction = fragmentFunction;
        renderPipelineDescriptor.vertexDescriptor = _vertexDescriptor;
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
    - (void) loadMeshAssets {
        
        MTKMeshBufferAllocator * bufferAllocator =
                [[MTKMeshBufferAllocator alloc] initWithDevice:_device];
        
        // Create a MDLVertexDescriptor from an existing MTLVertexDescriptor
        MDLVertexDescriptor * mdlVertexDescriptor =
                MTKModelIOVertexDescriptorFromMetal(_vertexDescriptor);
        
        // Specify vertex attribute type for each attribute location slot.
        auto mdlAttributes = mdlVertexDescriptor.attributes;
        mdlAttributes[Position].name = MDLVertexAttributePosition;
        mdlAttributes[Normal].name = MDLVertexAttributeNormal;
        mdlAttributes[TextureCoordinate].name = MDLVertexAttributeTextureCoordinate;
        
        
        NSURL * meshAssetURL = [[NSBundle mainBundle]
            URLForResource: @"Assets/Meshes/city.obj"
             withExtension: nil
        ];
        
        _cityMesh = [[Mesh alloc] initWithURLForAsset: meshAssetURL
                                      bufferAllocator: bufferAllocator
                                     vertexDescriptor: mdlVertexDescriptor
        ];
        
        
        meshAssetURL = [[NSBundle mainBundle]
            URLForResource: @"Assets/Meshes/groundplane.obj"
             withExtension: nil
        ];
        
        _groundPlaneMesh = [[Mesh alloc] initWithURLForAsset: meshAssetURL
                                      bufferAllocator: bufferAllocator
                                     vertexDescriptor: mdlVertexDescriptor
        ];
        
    }

    //-----------------------------------------------------------------------------------
    - (void) loadTextureAssets {
        //-- Load City Texture:
        {
            NSURL * textureAssetURL = [[NSBundle mainBundle]
                URLForResource: @"Assets/Textures/city.png"
                 withExtension: nil ];
            
            MTKTextureLoader * mtlTextureLoader =
                    [[MTKTextureLoader alloc] initWithDevice:_device];
            
            NSDictionary<NSString *, NSNumber *> * textureLoadingOptions =
            @{
                MTKTextureLoaderOptionAllocateMipmaps : @YES,
                MTKTextureLoaderOptionSRGB : @YES
            };
            
            NSError * error;
            
            _cityTexture =
                [mtlTextureLoader newTextureWithContentsOfURL: textureAssetURL
                                                      options: textureLoadingOptions
                                                        error: &error];
        }
        
        //-- Load Plane Texture:
        {
            NSURL * textureAssetURL = [[NSBundle mainBundle]
                URLForResource: @"Assets/Textures/groundplane.png"
                 withExtension: nil ];
            
            MTKTextureLoader * mtlTextureLoader =
                    [[MTKTextureLoader alloc] initWithDevice:_device];
            
            NSDictionary<NSString *, NSNumber *> * textureLoadingOptions =
            @{
                MTKTextureLoaderOptionAllocateMipmaps : @YES,
                MTKTextureLoaderOptionSRGB : @YES
            };
            
            NSError * error;
            
            _groundPlaneTexture =
                [mtlTextureLoader newTextureWithContentsOfURL: textureAssetURL
                                                      options: textureLoadingOptions
                                                        error: &error];
        }
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
        glm::mat4 modelMatrix = glm::scale(mat4(), vec3(20.0f, 20.f, 20.0f));
        glm::mat4 viewMatrix = camera.viewMatrix();
        glm::mat4 modelView = viewMatrix * modelMatrix;
        glm::mat3 normalMatrix = glm::transpose(glm::inverse(glm::mat3(modelView)));
        
        FrameUniforms frameUniforms = FrameUniforms();
        frameUniforms.modelMatrix = glm_mat4_to_matrix_float4x4(modelMatrix);
        frameUniforms.viewMatrix = glm_mat4_to_matrix_float4x4(viewMatrix);
        frameUniforms.projectionMatrix = glm_mat4_to_matrix_float4x4(camera.projectionMatrix());
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
    - (void) generateMipmapLevels: (id<MTLCommandBuffer>)commandBuffer {
        id<MTLBlitCommandEncoder> commandEncoder = [commandBuffer blitCommandEncoder];
        
        [commandEncoder generateMipmapsForTexture: _cityTexture];
        [commandEncoder generateMipmapsForTexture: _groundPlaneTexture];
        
        [commandEncoder endEncoding];
        [commandBuffer commit];
    }

    //-----------------------------------------------------------------------------------
    - (void) encodeRenderCommandInto:(id<MTLCommandBuffer>)commandBuffer
            withRenderPassDescriptor:(MTLRenderPassDescriptor *)renderPassDescriptor {
        
        renderPassDescriptor.colorAttachments[0].clearColor =
            MTLClearColorMake(0.1, 0.1, 0.1, 1.0);
        
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
        
        
        [renderEncoder setVertexBuffer: _frameUniformBuffers[_currentFrame]
                                offset: 0
                               atIndex: FrameUniformBufferIndex];
    
        
        //-- Render City with Texture
        {
            [renderEncoder setFragmentTexture: _cityTexture atIndex:0];
            
            auto samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
            samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
            samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
            samplerDescriptor.sAddressMode = MTLSamplerAddressModeRepeat;
            samplerDescriptor.tAddressMode = MTLSamplerAddressModeRepeat;
            samplerDescriptor.maxAnisotropy = 8;
            samplerDescriptor.mipFilter = MTLSamplerMipFilterLinear;
            
            auto sampler = [_device newSamplerStateWithDescriptor:samplerDescriptor];
            
            [renderEncoder setFragmentSamplerState:sampler atIndex:0];
            
            [_cityMesh renderWithEndcoder:renderEncoder];
        }
        
        //-- Render Ground Plane with Texture
        {
            [renderEncoder setFragmentTexture: _groundPlaneTexture atIndex:0];
            
            auto samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
            samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
            samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
            samplerDescriptor.sAddressMode = MTLSamplerAddressModeRepeat;
            samplerDescriptor.tAddressMode = MTLSamplerAddressModeRepeat;
            samplerDescriptor.maxAnisotropy = 8;
            samplerDescriptor.mipFilter = MTLSamplerMipFilterLinear;
            
            auto sampler = [_device newSamplerStateWithDescriptor:samplerDescriptor];
            
            [renderEncoder setFragmentSamplerState:sampler atIndex:0];
            
            [_groundPlaneMesh renderWithEndcoder:renderEncoder];
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

@end // DeferredShadingRenderer
