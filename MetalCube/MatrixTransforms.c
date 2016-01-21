//
//  MatrixTransforms.c
//  MetalSwift
//
//  Created by Dustin on 1/6/16.
//  Copyright © 2016 none. All rights reserved.
//

#include "MatrixTransforms.h"

#include "math.h"

#include <simd/simd.h>

//---------------------------------------------------------------------------------------
matrix_float4x4 matrix_from_perspective_fov_aspectLH (
        const float fovY,
        const float aspect,
        const float nearZ,
        const float farZ
) {
    // 1 / tan == cot
    float yscale = 1.0f / tanf(fovY * 0.5f);
    float xscale = yscale / aspect;
    float q = farZ / (farZ - nearZ);
    
    matrix_float4x4 m = {
        .columns[0] = { xscale, 0.0f, 0.0f, 0.0f },
        .columns[1] = { 0.0f, yscale, 0.0f, 0.0f },
        .columns[2] = { 0.0f, 0.0f, q, 1.0f },
        .columns[3] = { 0.0f, 0.0f, q * -nearZ, 0.0f }
    };
    
    return m;
}

//---------------------------------------------------------------------------------------
matrix_float4x4 matrix_from_translation (
        float x,
        float y,
        float z
) {
    matrix_float4x4 m = matrix_identity_float4x4;
    m.columns[3] = (vector_float4) { x, y, z, 1.0 };
    return m;
}

//---------------------------------------------------------------------------------------
matrix_float4x4 matrix_from_rotation (
        float radians,
        float x,
        float y,
        float z
) {
    vector_float3 v = vector_normalize(((vector_float3){x, y, z}));
    float cos = cosf(radians);
    float cosp = 1.0f - cos;
    float sin = sinf(radians);
    
    return (matrix_float4x4) {
        .columns[0] = {
            cos + cosp * v.x * v.x,
            cosp * v.x * v.y + v.z * sin,
            cosp * v.x * v.z - v.y * sin,
            0.0f,
        },
        
        .columns[1] = {
            cosp * v.x * v.y - v.z * sin,
            cos + cosp * v.y * v.y,
            cosp * v.y * v.z + v.x * sin,
            0.0f,
        },
        
        .columns[2] = {
            cosp * v.x * v.z + v.y * sin,
            cosp * v.y * v.z - v.x * sin,
            cos + cosp * v.z * v.z,
            0.0f,
        },
        
        .columns[3] = { 0.0f, 0.0f, 0.0f, 1.0f }
    };
}

//---------------------------------------------------------------------------------------
matrix_float3x3 sub_matrix_float3x3 (
        const matrix_float4x4 * m
) {
    vector_float4 col0 = m->columns[0];
    vector_float4 col1 = m->columns[1];
    vector_float4 col2 = m->columns[2];
    
    return (matrix_float3x3) {
        .columns[0] = {col0.x, col0.y, col0.z},
        .columns[1] = {col1.x, col1.y, col1.z},
        .columns[2] = {col2.x, col2.y, col2.z}
    };
}