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


//---------------------------------------------------------------------------------------
// Vertex Function
vertex float4 vertexFunction (
        VertexInput v_in [[stage_in]]
) {
    return float4(v_in.position, 1.0);
}


//---------------------------------------------------------------------------------------
// Fragment Function
fragment half4 fragmentFunction () {
    return half4(0.45, 0.1, 0.1, 1.0);
}