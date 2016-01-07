//
//  shaders.metal
//  MetalDemo
//
//  Created by Dustin on 12/27/15.
//  Copyright © 2015 none. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "ShaderUniforms.h"
#include "ShaderResourceIndices.h"

using namespace metal;

// Input to the vertex shader.
struct VertexInput {
    float3 position [[attribute(PositionAttributeIndex)]];
    float3 normal   [[attribute(NormalAttributeIndex)]];
};

// Output from Vertex shader.
struct VertexOutput {
    float4 position [[position]];
    half4 color;
};


//---------------------------------------------------------------------------------------
// Vertex Function
vertex VertexOutput vertexFunction (
        VertexInput v_in [[stage_in]],
        constant FrameUniforms & frameUniforms [[buffer(FrameUniformBufferIndex)]]
) {
    VertexOutput vOut;
    
    float4 pWorld = frameUniforms.modelMatrix * float4(v_in.position, 1.0);
    float4 pEye = frameUniforms.viewMatrix * pWorld;
    vOut.position = frameUniforms.projectionMatrix * pEye;
    vOut.color = half4(half3(v_in.normal), 1.0);
    
    return vOut;
}


//---------------------------------------------------------------------------------------
// Fragment Function
fragment half4 fragmentFunction (
        VertexOutput f_in [[stage_in]]
) {
    return f_in.color;
}