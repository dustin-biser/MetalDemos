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

// Variables in constant address space:
constant float3 light_position = float3(-1.0, 2.0, -1.0);


// Input to the vertex shader.
struct VertexInput {
    float3 position [[attribute(Position)]];
    float3 normal   [[attribute(Normal)]];
    float2 textureCoord   [[attribute(TextureCoordinate)]];
};

// Output from Vertex shader.
struct VertexOutput {
    float4 position [[position]];
    float3 eye_position; // Vertex position in eye-space.
    float3 eye_normal;   // Vertex normal in eye-space.
    float2 textureCoord; // (u,v) texture coordinates.
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
    
    vOut.eye_position = pEye.xyz;
    vOut.position = frameUniforms.projectionMatrix * pEye;
    vOut.eye_normal = normalize(frameUniforms.normalMatrix * v_in.normal);
    vOut.textureCoord = v_in.textureCoord;
    
    return vOut;
}


//---------------------------------------------------------------------------------------
// Fragment Function
fragment float4 fragmentFunction (
        VertexOutput f_in [[stage_in]],
        texture2d<float, access::sample> diffuseTexture [[ texture(0) ]],
        sampler samplerDiffuse [[ sampler(0) ]]
) {
    float3 l = normalize(light_position - f_in.eye_position);
    float n_dot_l = dot(f_in.eye_normal.rgb, l);
    n_dot_l = fmax(0.0, n_dot_l);
    
    float r = clamp(distance(light_position, f_in.eye_position), 0.2, 1.5);
    float fallOff = 1.0/r;
    
    const float4 diffuseColor = diffuseTexture.sample(samplerDiffuse, f_in.textureCoord);
    
    return diffuseColor;// * n_dot_l * fallOff;
}