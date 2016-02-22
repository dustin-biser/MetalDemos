//
//  shaders.metal
//  MetalDemo
//
//  Created by Dustin on 12/27/15.
//  Copyright © 2015 none. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Input to the vertex shader.
struct VertexInput {
    float3 position [[attribute(0)]];
};

// Output from Vertex shader.
struct VertexOutput {
    float4 position [[position]];
    half4 color;
};


//---------------------------------------------------------------------------------------
// Vertex Function
vertex VertexOutput vertexFunction (
        VertexInput v_in [[stage_in]]
) {
    VertexOutput vOut;
    
    vOut.position = float4(v_in.position, 1.0);
    vOut.color = half4(0.65, 0.3, 0.3, 1.0);
    
    return vOut;
}


//---------------------------------------------------------------------------------------
// Fragment Function
fragment half4 fragmentFunction (
        VertexOutput f_in [[stage_in]]
) {
    return f_in.color;
}