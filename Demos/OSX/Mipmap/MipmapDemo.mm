//
//  MipmapDemo.m
//  MetalDemos
//
//  Created by Dustin on 3/10/16.
//  Copyright © 2016 none. All rights reserved.
//

#import "MetalDemoCommon.h"
#import "MipmapDemo.h"
#import "MetalRenderer.h"
#import "Camera.hpp"

#import <simd/vector_types.h>
#import <memory>
using namespace std;


////////////////////////////////////////
// TODO: Remove this after testing
#include <iostream>
#include <glm/gtx/io.hpp>

////////////////////////////////////////


// Private methods
@interface MipmapDemo ()
    
    - (void) setupMetalView;

    - (void) setupCamera;

@end


@implementation MipmapDemo {
@private
    MetalRenderer * _metalRenderer;
    
    shared_ptr<Camera> _camera;
}

    //-----------------------------------------------------------------------------------
    - override (void)viewWillAppear {
        [super viewWillAppear];
        [self setupMetalView];
        [self setupCamera];
        
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
        _metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
        _metalView.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
        _metalView.framebufferOnly = true;
    }

    //-----------------------------------------------------------------------------------
    - (void) setupCamera {
        _camera = std::make_shared<Camera>();
        
        _camera->lookAt(
                glm::vec3(0.0f, 10.2f, 55.4f),
                glm::vec3(0.0f, 0.0f, 0.0f),
                glm::vec3(0.0f, 1.0f, 0.0f)
       );
    }

    //-----------------------------------------------------------------------------------
    - override (void) viewSizeChanged:(MTKView *)view
                    newSize:(CGSize)size {
    
        [_metalRenderer reshape: size];
    }

    //-----------------------------------------------------------------------------------
    - override (void) draw:(id<MTLCommandBuffer>)commandBuffer {
        [_metalRenderer render: commandBuffer
          renderPassDescriptor: _metalView.currentRenderPassDescriptor
                        camera: (*_camera)];
    }


    //-----------------------------------------------------------------------------------
    - (void) keyDown:(NSEvent *)theEvent {
        const float deltaTranslation(0.2f);
        const float deltaRotation(0.05f);
        
        char unicodeChar = [theEvent.charactersIgnoringModifiers characterAtIndex:0];
        
        switch (unicodeChar) {
            case 'w': {
                _camera->translate(glm::vec3(0.0f, 0.0f, -deltaTranslation));
                break;
            }
                
            case 's': {
                _camera->translate(glm::vec3(0.0f, 0.0f, deltaTranslation));
                break;
            }
                
            case 'r': {
                _camera->translate(glm::vec3(0.0f, deltaTranslation, 0.0f));
                break;
            }
                
            case 'f': {
                _camera->translate(glm::vec3(0.0f, -deltaTranslation, 0.0f));
                break;
            }
                
            case 'q': {
                _camera->rotate(deltaRotation, glm::vec3(0.0f, 1.0f, 0.0f));
                break;
            }
                
            case 'e': {
                _camera->rotate(-deltaRotation, glm::vec3(0.0f, 1.0f, 0.0f));
                break;
            }
                
            default:
                break;
        }
    }

@end // MipmapDemo
