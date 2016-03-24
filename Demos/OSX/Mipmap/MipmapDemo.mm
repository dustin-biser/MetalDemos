//
//  MipmapDemo.m
//  MetalDemos
//
//  Created by Dustin on 3/10/16.
//  Copyright © 2016 none. All rights reserved.
//

#import "MetalDemoCommon.h"
#import "MipmapDemo.h"
#import "MipmapRenderer.h"
#import "Camera.hpp"

#import <simd/vector_types.h>
#import <memory>
using namespace std;


// Private methods
@interface MipmapDemo ()
    
    - (void) setupMetalView;

    - (void) setupCamera;

    - (void) generateMipmapLevels;
@end


@implementation MipmapDemo {
@private
    MipmapRenderer * _renderer;
    
    shared_ptr<Camera> _camera;
    
    bool _KEY_W_DOWN;
}

    //-----------------------------------------------------------------------------------
    - override (void)viewWillAppear {
        [super viewWillAppear];
        [self setupMetalView];
        [self setupCamera];
        
        // TripleBuffer rendering of frames.
        _numBufferedFrames = 3;
        
        MipmapRenderDescriptor * metalRenderDescriptor = [[MipmapRenderDescriptor alloc] init];
        metalRenderDescriptor.device = _device;
        metalRenderDescriptor.shaderLibrary = _defaultShaderLibrary;
        metalRenderDescriptor.msaaSampleCount = (int)_metalView.sampleCount;
        metalRenderDescriptor.colorPixelFormat = _metalView.colorPixelFormat;
        metalRenderDescriptor.depthStencilPixelFormat= _metalView.depthStencilPixelFormat;
        metalRenderDescriptor.stencilAttachmentPixelFormat = _metalView.depthStencilPixelFormat;
        metalRenderDescriptor.framebufferWidth = _metalView.drawableSize.width;
        metalRenderDescriptor.framebufferHeight = _metalView.drawableSize.height;
        metalRenderDescriptor.numBufferedFrames = _numBufferedFrames;
        
        _renderer = [[MipmapRenderer alloc] initWithDescriptor: metalRenderDescriptor];
        
        [self generateMipmapLevels];
        
        _KEY_W_DOWN = false;
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
        float width = float(_metalView.drawableSize.width);
        float height = float(_metalView.drawableSize.height);
        float aspect = width / height;
        float fovy = 65.0f * (M_PI / 180.0f);
        float nearPlaneDistance = 0.1f;
        float farPlaneDistance = 100.0f;
        _camera = std::make_shared<Camera> (
            fovy, aspect, nearPlaneDistance, farPlaneDistance
        );
        
        _camera->lookAt(
                glm::vec3(0.0f, 112.2f, 1140.5f),
                glm::vec3(0.0f, 0.0f, 100.0f),
                glm::vec3(0.0f, 1.0f, 0.0f)
       );
    }

    //-----------------------------------------------------------------------------------
    - (void) generateMipmapLevels {
        id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
        
        [_renderer generateMipmapLevels: commandBuffer];
    }

    //-----------------------------------------------------------------------------------
    - override (void) viewSizeChanged:(MTKView *)view
                    newSize:(CGSize)size {
    
        [_renderer reshape: size];
    }

    //-----------------------------------------------------------------------------------
    - override (void) draw:(id<MTLCommandBuffer>)commandBuffer {
        [_renderer render: commandBuffer
          renderPassDescriptor: _metalView.currentRenderPassDescriptor
                        camera: (*_camera)];
        
        const float deltaTranslation(1.5f);
        if(_KEY_W_DOWN) {
            _camera->translateLocal(glm::vec3(0.0f, 0.0f, -deltaTranslation));
        }
    }

    //-----------------------------------------------------------------------------------
    - override (void) keyUp:(NSEvent *)theEvent {
        char unicodeChar = [theEvent.charactersIgnoringModifiers characterAtIndex:0];
        
        switch (unicodeChar) {
            case 'w': {
                _KEY_W_DOWN = false;
                break;
            }
                
            default: {
                break;
            }
        }
        
    }


    //-----------------------------------------------------------------------------------
    - override (void) keyDown:(NSEvent *)theEvent {
        const float deltaTranslation(1.5f);
        const float deltaRotation = 0.05f;
        
        char unicodeChar = [theEvent.charactersIgnoringModifiers characterAtIndex:0];
        
        switch (unicodeChar) {
            case 'w': {
                _KEY_W_DOWN = true;
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
                _camera->yaw(deltaRotation);
                break;
            }
                
            case 'e': {
                _camera->yaw(-deltaRotation);
                break;
            }
                
            default:
                break;
        }
        
    }

@end // MipmapDemo
