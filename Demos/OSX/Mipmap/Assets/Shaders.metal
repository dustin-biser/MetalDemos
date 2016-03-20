//
//  shaders.metal
//  MetalDemo
//
//  Created by Dustin on 12/27/15.
//  Copyright © 2015 none. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "ShaderUniforms.hpp"
#include "ShaderResourceIndices.h"

using namespace metal;

// Variables in constant address space:
constant float3 light_position = float3(-1.0, 2.0, -1.0);
constant half3 diffuse = half3(0.08, 0.08, 0.3);


// Input to the vertex shader.
struct VertexInput {
    float3 position [[attribute(PositionAttribute)]];
    float3 normal   [[attribute(NormalAttribute)]];
};


// Output from Vertex shader.
struct VertexOutput {
    float4 position_CS [[position]];  // Clip-space position.
    float3 position_VS; // Vertex position in view-space.
    float3 normal_VS;   // Vertex normal in view-space.
};


//---------------------------------------------------------------------------------------
// Vertex Function
vertex VertexOutput vertexFunction (
        VertexInput v_in [[stage_in]],
        constant FrameUniforms & frameUniforms [[buffer(FrameUniformBufferIndex)]]
) {
    VertexOutput vOut;
    
    // Vertex position in world space.
    float4 vertexPosition_WS = frameUniforms.modelMatrix * float4(v_in.position, 1.0);
    
    // Vertex position in view space.
    float4 vertexPosition_VS = frameUniforms.viewMatrix * vertexPosition_WS;
    
    vOut.position_CS = frameUniforms.projectionMatrix * vertexPosition_VS;
    vOut.position_VS = vertexPosition_VS.xyz;
    vOut.normal_VS = normalize(frameUniforms.normalMatrix * v_in.normal);
    
    return vOut;
}


//---------------------------------------------------------------------------------------
// Fragment Function
fragment half4 fragmentFunction (
        VertexOutput f_in [[stage_in]]
) {
    float3 l = normalize(light_position - f_in.position_VS);
    float n_dot_l = dot(f_in.normal_VS.rgb, l);
    n_dot_l = fmax(0.0, n_dot_l);
    
    float r = clamp(distance(light_position, f_in.position_VS), 0.2, 1.5);
    float fallOff = 1.0/r;
    
    return half4(diffuse * n_dot_l, 1.0) * fallOff;
}