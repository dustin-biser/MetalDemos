//
//  Mesh.h
//  MetalDemos
//
//  Created by Dustin on 3/29/16.
//  Copyright © 2016 none. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>


//-- Forward Declarations:
@class NSURL;
@class MTKMeshBufferAllocator;
@class MDLVertexDescriptor;
@protocol MTLRenderCommandEncoder;


@interface Mesh : NSObject

    - (instancetype) initWithURLForAsset: (NSURL *)meshAssetURL
                         bufferAllocator: (MTKMeshBufferAllocator *)allocator
                        vertexDescriptor: (MDLVertexDescriptor *)mdlVertexDescriptor;

    - (void) renderWithEndcoder: (id<MTLRenderCommandEncoder>)renderEncoder;

@end
