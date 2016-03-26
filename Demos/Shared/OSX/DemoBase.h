//
//  ViewController.h
//  Mipmap
//
//  Created by Dustin on 3/7/16.
//  Copyright © 2016 none. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Metal/Metal.h>

#import "MetalView.h"
#import "InputHandler.hpp"

#import <memory>


@interface DemoBase : NSViewController <MTKViewDelegate> {
@protected
    MetalView * _metalView;
    
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLLibrary> _defaultShaderLibrary;
    
    int _numBufferedFrames;
    
    
    std::shared_ptr<InputHandler> _inputHandler;
}

    /*!
     * @brief Called once per frame before the DemoBase::draw method
     * @discussion Derived classes should override this method and do any non-rendering
     * tasks related to application logic, such as user input.
     */
    - (void) appLogic;

    /*!
      @abstract Called once per frame to perform rendering to this class's MTKView.
      @param commandBuffer Used to encode render commands into.
    */
    - (void) draw:(nonnull id<MTLCommandBuffer>)commandBuffer;

    /*!
       @abstract Called once the size of the MTKView changes.
     */
    - (void) viewSizeChanged:(nonnull MTKView *)view newSize:(struct CGSize)size;


    - (void) disableCursor;


    - (void) enableCursor;


@end // DemoBase

