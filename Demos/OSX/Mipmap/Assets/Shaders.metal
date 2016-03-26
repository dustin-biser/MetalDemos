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
    float3 position [[ attribute(PositionAttribute) ]];
    float3 normal   [[ attribute(NormalAttribute) ]];
    float2 textureCoord [[ attribute(TextureCoordinateAttribute) ]];
};


// Output from Vertex shader.
struct VertexOutput {
    float4 position_CS [[position]];  // Clip-space position.
    float3 position_VS; // Vertex position in view-space.
    float3 normal_VS;   // Vertex normal in view-space.
    float2 textureCoord; // (u,v) texture coordinates.
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
    const float2 textureSize = float2(2048, 2048);
    
    const float2 uv = f_in.textureCoord * textureSize;
    const float dudx = dfdx(uv.x);
    const float dvdx = dfdx(uv.y);
    const float dudy = dfdy(uv.x);
    const float dvdy = dfdy(uv.y);
    
    const float p = max(sqrt(dudx*dudx + dvdx*dvdx), sqrt(dudy*dudy + dvdy*dvdy));
    const float lod = floor(max(0.0f, log2(p)));
    float normLod = lod / diffuseTexture.get_num_mip_levels();
    
    float4 diffuseColor = diffuseTexture.sample(samplerDiffuse, f_in.textureCoord);
    
    float4 mipMapHighestLevelColor = float4(1.0, 0.0, 0.0f, 0.0f);
    float4 mipMapLowestLevelColor = float4(1.0, 1.0, 1.0f, 0.0f);
    float4 mipMapColor = mix(mipMapLowestLevelColor, mipMapHighestLevelColor, normLod);
    
    return mix(diffuseColor, mipMapColor, normLod + 0.2f);
}