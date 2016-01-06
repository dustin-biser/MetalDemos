//
//  ShaderResourceIndices.h
//  MetalSwift
//
//  Created by Dustin on 1/5/16.
//  Copyright © 2016 none. All rights reserved.
//

#pragma once

/// Vertex attribute indices
enum IndexForVertexAttribute {
    PositionAttributeIndex      = 0,
    NormalAttributeIndex        = 1,
    TextureCoordAttributeIndex  = 2
};

/// Buffer indices
enum IndexForBuffer {
    VertexBufferIndex           = 0,
    FrameUniformBufferIndex     = 1,
    MaterialUniformBufferIndex  = 2
};