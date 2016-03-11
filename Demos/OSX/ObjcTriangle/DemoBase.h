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


@interface DemoBase : NSViewController <MTKViewDelegate>

    /*!
      @abstract Called once per frame to perform rendering to this class's MTKView.
      @param commandBuffer Used to encode render commands into.
    */
    - (void) draw:(nonnull id<MTLCommandBuffer>)commandBuffer;

    /*!
       @abstract Called once the size of the MTKView changes.
     */
    - (void) viewSizeChanged:(nonnull MTKView *)view newSize:(struct CGSize)size;


@end // DemoBase
