//
//  Mesh.mm
//  MetalDemos
//
//  Created by Dustin on 3/29/16.
//  Copyright © 2016 none. All rights reserved.
//

#import "Mesh.h"
#import "ShaderResourceIndices.h"

#import <Metal/Metal.h>
#import <MetalKit/MTKModel.h>


@implementation Mesh {
    MTKMesh * _mesh;
}

    //-----------------------------------------------------------------------------------
    - (instancetype) initWithURLForAsset: (NSURL *)meshAssetURL
                         bufferAllocator: (MTKMeshBufferAllocator *)allocator
                        vertexDescriptor: (MDLVertexDescriptor *)mdlVertexDescriptor
    {
        self = [super init];
        if(!self) {
            return nil;
        }
        
        NSError * errors = nil;
        MDLAsset * asset =
            [[MDLAsset alloc] initWithURL: meshAssetURL
                         vertexDescriptor: mdlVertexDescriptor
                          bufferAllocator: allocator
                         preserveTopology: NO
                                    error: &errors];
        if(errors) {
            NSLog(@"Error loading mesh assset: %@.\n With Error: %@", meshAssetURL, errors);
            throw;
        }


        NSArray<MTKMesh *> * meshArray =
            [MTKMesh newMeshesFromAsset: asset
                                 device: allocator.device
                           sourceMeshes: nil
                                  error: &errors];
        if(errors) {
            NSLog(@"Error loading assset: %@.\n With Error: %@", meshAssetURL, errors);
            throw;
        }
        
        _mesh = meshArray[0];

        
        return self;
    }

    //-----------------------------------------------------------------------------------
    - (void) renderWithEndcoder: (id<MTLRenderCommandEncoder>)renderEncoder {

        for(MTKMeshBuffer * vertexBuffer in _mesh.vertexBuffers) {
            [renderEncoder setVertexBuffer: vertexBuffer.buffer
                                    offset: vertexBuffer.offset
                                   atIndex: VertexBufferIndex];
        }

        for(MTKSubmesh * subMesh in _mesh.submeshes) {
            [renderEncoder drawIndexedPrimitives: MTLPrimitiveTypeTriangle
                                      indexCount: subMesh.indexCount
                                       indexType: subMesh.indexType
                                     indexBuffer: subMesh.indexBuffer.buffer
                               indexBufferOffset: subMesh.indexBuffer.offset
             ];
        }
        
    }

@end // end class Mesh
