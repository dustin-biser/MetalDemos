//
//  ShaderUniforms.h
//  MetalSwift
//
//  Created by Dustin on 1/6/16.
//  Copyright © 2016 none. All rights reserved.
//

#pragma once

#include <simd/vector_types.h>

/// Per frame uniforms.
struct FrameUniforms {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 projectionViewMatrix;
    matrix_float4x4 normalMatrix;
};
