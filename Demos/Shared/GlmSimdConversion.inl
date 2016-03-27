//
//  GlmSimdConversion.inl
//  MetalDemos
//
//  Created by Dustin on 3/27/16.
//  Copyright © 2016 none. All rights reserved.
//

//---------------------------------------------------------------------------------------
inline glm::mat4 matrix_float4x4_to_glm_mat4(const matrix_float4x4 & mat) {
    return glm::mat4 {
        glm::vec4{mat.columns[0][0], mat.columns[0][1], mat.columns[0][2], mat.columns[0][3]},
        glm::vec4{mat.columns[1][0], mat.columns[1][1], mat.columns[1][2], mat.columns[1][3]},
        glm::vec4{mat.columns[2][0], mat.columns[2][1], mat.columns[2][2], mat.columns[2][3]},
        glm::vec4{mat.columns[3][0], mat.columns[3][1], mat.columns[3][2], mat.columns[3][3]},
    };
    
}

//---------------------------------------------------------------------------------------
inline matrix_float4x4 glm_mat4_to_matrix_float4x4(const glm::mat4 & mat) {
    return matrix_float4x4 {
        .columns[0] = {mat[0][0], mat[0][1], mat[0][2], mat[0][3]},
        .columns[1] = {mat[1][0], mat[1][1], mat[1][2], mat[1][3]},
        .columns[2] = {mat[2][0], mat[2][1], mat[2][2], mat[2][3]},
        .columns[3] = {mat[3][0], mat[3][1], mat[3][2], mat[3][3]},
    };
}

//---------------------------------------------------------------------------------------
inline matrix_float3x3 glm_mat3_to_matrix_float3x3(const glm::mat3 & mat) {
    return matrix_float3x3 {
        .columns[0] = {mat[0][0], mat[0][1], mat[0][2]},
        .columns[1] = {mat[1][0], mat[1][1], mat[1][2]},
        .columns[2] = {mat[2][0], mat[2][1], mat[2][2]}
    };
}
