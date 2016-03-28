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
    const float2 textureSize = float2(diffuseTexture.get_width(),
                                      diffuseTexture.get_height());
    
    const float2 uv = f_in.textureCoord * textureSize;
    const float2 ddx = dfdx(uv);
    const float2 ddy = dfdy(uv);
    
    const float p = max(sqrt(dot(ddx,ddx)), sqrt(dot(ddy,ddy)));
    const float lod = floor(max(0.0f, log2(p)));
    const float normLod = lod / diffuseTexture.get_num_mip_levels();
    
    const float4 diffuseColor = diffuseTexture.sample(samplerDiffuse, f_in.textureCoord);
    
    const float4 mipMapHighestLevelColor = float4(1.0, 0.0, 0.0f, 1.0f);
    const float4 mipMapLowestLevelColor = float4(1.0, 1.0, 1.0f, 1.0f);
    const float4 mipMapColor = mix(mipMapLowestLevelColor, mipMapHighestLevelColor, normLod);
    
    return mix(diffuseColor, mipMapColor, normLod + 0.2f);
}