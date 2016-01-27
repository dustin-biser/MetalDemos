//
//  ShaderResourceIndices.h
//  MetalSwift
//
//  Created by Dustin on 1/5/16.
//  Copyright © 2016 none. All rights reserved.
//

/**
 Resouce indices to be made available witin .swift and .metal files.
 
 Note that the Metal shading lanuage does not support long types, but
 attribute and buffer indices from .swift files require type Int which
 is convertable from a C long.
 
 The trick is to make sure METAL=1 is set within the Xcode project's metal
 "Preprocessor Definitions" build setting so the metal preprocessor can choose
 indices to be of type int rather than type long.
 */

#pragma once


#if defined(METAL)
    typedef int int_type;
#else
    typedef long int_type;
#endif


//---------------------------------------------------------------------------------------
/// Vertex attribute indices
enum IndexForVertexAttribute : int_type {
    PositionAttributeIndex      = 0,
    NormalAttributeIndex        = 1,
    TextureCoordAttributeIndex  = 2
};

//---------------------------------------------------------------------------------------
/// Buffer indices
enum IndexForBuffer : int_type {
    VertexBufferIndex           = 0,
    FrameUniformBufferIndex     = 1,
    MaterialUniformBufferIndex  = 2
};
