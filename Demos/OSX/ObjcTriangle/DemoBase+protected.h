//
//  DemoBase+protected.h
//  MetalDemos
//
//  Created by Dustin on 3/10/16.
//  Copyright © 2016 none. All rights reserved.
//

#import <MetalKit/MetalKit.h>

@interface DemoBase () {
    
@protected
    MetalView * _metalView;
    
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLLibrary> _defaultShaderLibrary;
    
    int _numBufferedFrames;
}

@end