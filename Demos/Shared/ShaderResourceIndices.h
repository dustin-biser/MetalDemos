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
    // Metal variables defined in program scope, must have the 'constant' address-space
    // qualifier and be initialized during declaration.
    #define int_type constexpr constant int
#else
    typedef long int_type;
#endif

//---------------------------------------------------------------------------------------
/// Vertex Attribute Indices:
extern int_type Position ;
extern int_type Normal;
extern int_type TextureCoordinate;


//---------------------------------------------------------------------------------------
/// Vertex Buffer Indices
extern int_type VertexBufferIndex;
extern int_type FrameUniformBufferIndex;
extern int_type InstanceUniformBufferIndex;
extern int_type MaterialUniformBufferIndex;
