//
//  DemoBase.m

//  Created by Dustin on 3/7/16.
//  Copyright © 2016 none. All rights reserved.
//

#import "MetalDemoCommon.h"
#import "DemoBase.h"
#import "InputHandler.hpp"

#import <MetalKit/MetalKit.h>


// Private members
@interface DemoBase ()

    - (void) setupMetal;

    - (void) setupView;

    - (void) handleInput;

@end



@implementation DemoBase {
@private
    dispatch_semaphore_t _inflightSemaphore;
    
    bool _cursorIsEnabled;
}

    //-----------------------------------------------------------------------------------
    - override (void)viewWillAppear {
        [super viewWillAppear];
        
        [self setupMetal];
        
        [self setupView];
        
        _metalView.device = _device;
        _metalView.preferredFramesPerSecond = 60;
        
        // Setup semaphore and number of buffered frames:
        _numBufferedFrames = 1;
        _inflightSemaphore = dispatch_semaphore_create(_numBufferedFrames);
        
        // Create InputHandler
        _inputHandler = std::make_shared<InputHandler>();
        
        _cursorIsEnabled = true;
    }


    //-----------------------------------------------------------------------------------
    - (void) setupMetal {
        
        _device = MTLCreateSystemDefaultDevice();
        if (_device == nil) {
            NSLog(@"Error creating default MTLDevice.");
            exit(0);
        }
    
        _defaultShaderLibrary = [_device newDefaultLibrary];
        if (_defaultShaderLibrary == nil) {
            NSLog(@"Error creating default shader library.\n"
                  "Check that a .metal file has been added to the target's Compile "
                  "Sources list.");
            exit(0);
        }
        
        _commandQueue = [_device newCommandQueue];
        
    }

    //-----------------------------------------------------------------------------------
    - (void) setupView {
        
        _metalView = (MetalView *)self.view;
    
        // This class will handle drawing to the MTKView
        _metalView.delegate = self;
        
        //-- Add self to Responder Chain so it can handle key and mouse input events.
        // Responder Chain order:
        // MetalView -> ViewController -> Window -> WindowController
        NSWindow * window = _metalView.window;
        if(window == nil) {
            NSLog(@"The current View has no attached NSWindow.");
            exit(0);
        }
        window.initialFirstResponder = _metalView;
        _metalView.nextResponder = self;
        self.nextResponder = _metalView.window;
        
        //-- Add mouse tracking to the MetalView:
        NSTrackingAreaOptions trackingOptions =
            NSTrackingInVisibleRect | NSTrackingMouseMoved |
            NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp;
        
        NSTrackingArea * trackingArea = [[NSTrackingArea alloc]
             initWithRect: _metalView.visibleRect
                  options: trackingOptions
                    owner:self
                 userInfo:nil
        ];
        
        [_metalView addTrackingArea:trackingArea];
        
    }

    //-----------------------------------------------------------------------------------
    - (void) appLogic {
        // Override this method.
    }

    //-----------------------------------------------------------------------------------
    - (void) draw:(id<MTLCommandBuffer>)commandBuffer {
        // Override this method.
    }

    //-----------------------------------------------------------------------------------
    - (void) disableCursor {
        if (_cursorIsEnabled) {
            [NSCursor hide];
            CGAssociateMouseAndMouseCursorPosition(false);
            _cursorIsEnabled = false;
        }
 
    }

    //-----------------------------------------------------------------------------------
    - (void) enableCursor {
        if (!_cursorIsEnabled) {
            CGAssociateMouseAndMouseCursorPosition(true);
            [NSCursor unhide];
            _cursorIsEnabled = true;
        }
    }

    //-----------------------------------------------------------------------------------
    /// Called once the size of the MTKView changes.
    - (void) viewSizeChanged:(MTKView *)view newSize:(struct CGSize)size {
        // Override this method.
    }
    
    //-----------------------------------------------------------------------------------
    - (void) keyUp:(NSEvent *)theEvent {
        char character = [theEvent.charactersIgnoringModifiers characterAtIndex:0];
        _inputHandler->keyUp(character);
    }
    
    //-----------------------------------------------------------------------------------
    - (void) keyDown:(NSEvent *)theEvent {
        char character = [theEvent.charactersIgnoringModifiers characterAtIndex:0];
        _inputHandler->keyDown(character);
    }
    
    //-----------------------------------------------------------------------------------
    - (void) mouseEntered:(NSEvent *)theEvent {
        // Override this method.
    }
    
    //-----------------------------------------------------------------------------------
    - (void) mouseExited:(NSEvent *)theEvent {
        // Override this method.
    }
    
    //-----------------------------------------------------------------------------------
    - (void) mouseMoved:(NSEvent *)theEvent {
        // Override this method.
    }
    
    //-----------------------------------------------------------------------------------
    - (void) mouseDragged:(NSEvent *)theEvent {
        // Override this method.
    }
    
    //-----------------------------------------------------------------------------------
    - (void) mouseDown:(NSEvent *)theEvent {
        // Override this method.
    }
    
    //-----------------------------------------------------------------------------------
    - (void) mouseUp:(NSEvent *)theEvent {
        // Override this method.
    }
    
    //-----------------------------------------------------------------------------------
    - (void) scrollWheel:(NSEvent *)theEvent {
        // Override this method.
    }

    //-----------------------------------------------------------------------------------
    - (void) handleInput {
        
        //-- Register mouse cursor movement deltas:
        {
            int deltaX, deltaY;
            CGGetLastMouseDelta(&deltaX, &deltaY);
            
            // If cursor is enabled, prevent mouseMoved function calls
            if (_cursorIsEnabled) {
                deltaX = deltaY = 0;
            }
            _inputHandler->mouseMoved(deltaX, deltaY);
        }
        
        
        // Call functions registered to key input and mouse events.
        _inputHandler->handleInput();
    }


    //-----------------------------------------------------------------------------------
    // Called whenever the drawableSize of the view will change
    - override (void) mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
        [self viewSizeChanged:view newSize: size];
    }

    //-----------------------------------------------------------------------------------
    // Called once per frame to update view.
    - override (void) drawInMTKView:(MTKView *)view {
        @autoreleasepool {
            // Preflight frames on the CPU (using a semaphore as a guard) and commit them
            // to the GPU.  This semaphore will get signaled once the GPU completes a
            // frame's work via addCompletedHandler callback below, signifying the CPU
            // can go ahead and prepare another frame.
            dispatch_semaphore_wait(_inflightSemaphore, DISPATCH_TIME_FOREVER);
            
            [self appLogic];
            
            [self handleInput];
            
            id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
            
            // Tell the derived class to encode commands into the commandBuffer.
            [self draw: commandBuffer];
            
            [commandBuffer presentDrawable:_metalView.currentDrawable];
            
            // Once GPU has completed executing the commands within this buffer, signal
            // the semaphore and allow the CPU to proceed in constructing the next frame.
            __block dispatch_semaphore_t block_semaphore = _inflightSemaphore;
            [commandBuffer addCompletedHandler: ^(id<MTLCommandBuffer> buffer) {
                dispatch_semaphore_signal(block_semaphore);
            }];
            
            // Push command buffer to GPU for execution.
            [commandBuffer commit];
        }
    }

@end
