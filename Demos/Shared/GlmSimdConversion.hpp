//
//  GlmSimdConversion.hpp
//  MetalDemos
//
//  Created by Dustin on 3/27/16.
//  Copyright © 2016 none. All rights reserved.
//

#pragma once

#include "glm/glm.hpp"
#include <simd/matrix_types.h>

glm::mat4 matrix_float4x4_to_glm_mat4(const matrix_float4x4 & mat);

matrix_float4x4 glm_mat4_to_matrix_float4x4(const glm::mat4 & mat);

matrix_float3x3 glm_mat3_to_matrix_float3x3(const glm::mat3 & mat);


#include "GlmSimdConversion.inl"

