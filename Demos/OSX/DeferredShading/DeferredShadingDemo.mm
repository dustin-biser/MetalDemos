//
//  DeferredShadingDemo.m
//  MetalDemos
//
//  Created by Dustin on 3/10/16.
//  Copyright © 2016 none. All rights reserved.
//

#import "MetalDemoCommon.h"
#import "DeferredShadingDemo.h"
#import "DeferredShadingRenderer.h"
#import "Camera.hpp"

#import <simd/vector_types.h>
#import <memory>
using namespace std;


// Private methods
@interface DeferredShadingDemo ()
    
    - (void) setupMetalView;

    - (void) setupCamera;

    - (void) setupInputHandler;

    - (void) generateMipmapLevels;

    - (void) moveCamera;
@end


@implementation DeferredShadingDemo {
@private
    DeferredShadingRenderer * _renderer;
    
    shared_ptr<Camera> _camera;
    
    glm::vec3 _cameraMoveDirection;
    
    float _cameraMoveSpeed;
}

    //-----------------------------------------------------------------------------------
    - override (void)viewWillAppear {
        [super viewWillAppear];
        [self setupMetalView];
        [self setupCamera];
        [self setupInputHandler];
        
        // TripleBuffer rendering of frames.
        _numBufferedFrames = 3;
        
        DeferredShadingRenderDescriptor * metalRenderDescriptor = [[DeferredShadingRenderDescriptor alloc] init];
        metalRenderDescriptor.device = _device;
        metalRenderDescriptor.shaderLibrary = _defaultShaderLibrary;
        metalRenderDescriptor.msaaSampleCount = (int)_metalView.sampleCount;
        metalRenderDescriptor.colorPixelFormat = _metalView.colorPixelFormat;
        metalRenderDescriptor.depthStencilPixelFormat= _metalView.depthStencilPixelFormat;
        metalRenderDescriptor.stencilAttachmentPixelFormat = _metalView.depthStencilPixelFormat;
        metalRenderDescriptor.framebufferWidth = _metalView.drawableSize.width;
        metalRenderDescriptor.framebufferHeight = _metalView.drawableSize.height;
        metalRenderDescriptor.numBufferedFrames = _numBufferedFrames;
        
        _renderer = [[DeferredShadingRenderer alloc] initWithDescriptor: metalRenderDescriptor];
        
        [self generateMipmapLevels];
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
                glm::vec3(3.161f, 15.049f, 7.802f),
                glm::vec3(15.0f, 0.0f, -15.0f),
                glm::vec3(0.0f, 1.0f, 0.0f)
       );
        
        _cameraMoveDirection = glm::vec3(0.0f);
        _cameraMoveSpeed = 0.2f;
    }


    //-----------------------------------------------------------------------------------
    - (void) setupInputHandler {
        _inputHandler->registerKeyCommand(InputKey::C, [=] {
            [self disableCursor];
        });
        
        _inputHandler->registerKeyCommand(InputKey::V, [=] {
            [self enableCursor];
        });
        
        // Camera Translations:
        {
            _inputHandler->registerKeyCommand(InputKey::W, [=] {
                _cameraMoveDirection += _camera->forwardDirection();
            });
            
            _inputHandler->registerKeyCommand(InputKey::S, [=] {
                _cameraMoveDirection += _camera->backDirection();
            });
            
            _inputHandler->registerKeyCommand(InputKey::A, [=] {
                _cameraMoveDirection += _camera->strafeLeftDirection();
            });
            
            _inputHandler->registerKeyCommand(InputKey::D, [=] {
                _cameraMoveDirection += _camera->strafeRightDirection();
            });
            
            _inputHandler->registerKeyCommand(InputKey::R, [=] {
                // Elevate camera with respect to world space.
                _cameraMoveDirection += glm::vec3(0.0f, 1.0f, 0.0f);
            });
            
            _inputHandler->registerKeyCommand(InputKey::F, [=] {
                // Lower camera with respect to world space.
                _cameraMoveDirection += glm::vec3(0.0f, -1.0f, 0.0f);
            });
        }
        
        
        // Camera Rotations:
        {
            const float deltaRotation(0.02f);
            
            _inputHandler->registerKeyCommand(InputKey::Q, [=] {
                _camera->roll(deltaRotation);
            });
            
            _inputHandler->registerKeyCommand(InputKey::E, [=] {
                _camera->roll(-deltaRotation);
            });
            
            _inputHandler->registerMouseMoveCommand(
                [=] (float cursorDeltaX, float cursorDeltaY) {
                    const float scale(0.002);
                    // World space rotation
                    _camera->rotate(-cursorDeltaX * scale, glm::vec3(0.0f, 1.0f, 0.0f));
                    
                    // Local rotation
                    _camera->pitch(-cursorDeltaY * scale);
            });
        }
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
    - (void) moveCamera {
        if ( glm::dot(_cameraMoveDirection, _cameraMoveDirection) > FLT_EPSILON ) {
            // Make sure movement direction is of unit length
            _cameraMoveDirection = glm::normalize(_cameraMoveDirection);
            
            // Now translate camera using specific speed
            _camera->translate(_cameraMoveDirection *_cameraMoveSpeed);
            
            // Reset Camera move direction
            _cameraMoveDirection = glm::vec3(0.0f);
        }
    }


    //-----------------------------------------------------------------------------------
    - (void) appLogic {
        [self moveCamera];
    }

    //-----------------------------------------------------------------------------------
    - override (void) draw:(id<MTLCommandBuffer>)commandBuffer {
        [_renderer render: commandBuffer
          renderPassDescriptor: _metalView.currentRenderPassDescriptor
                        camera: (*_camera)];
    }


@end // DeferredShadingDemo
