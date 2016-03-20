//
//  Camera.hpp
//  MetalDemos
//
//  Created by Dustin on 3/16/16.
//  Copyright © 2016 none. All rights reserved.
//

#pragma once

#include <glm/glm.hpp>


class CameraImpl;


class Camera {
public:
    /// Constructor
    Camera();
    
    /// Destructor
    ~Camera();
    
    
    void lookAt (
        const glm::vec3 & cameraPosition,
        const glm::vec3 & focusPosition,
        const glm::vec3 & upDirection
    );
    
    
    glm::mat4 viewMatrix() const;
    
    /*!
     * @return the world space position of Camera.
     */
    glm::vec3 position() const;
    
    
    /*!
     * @brief Translates the Camera with respect to world space coordinates.
     * @param vec translation amounts along world space x, y, z axes.
     */
    void translate (
        const glm::vec3 & vec
    );
    
    void rotate (
        const float angle,
        const glm::vec3 & axis
    );
    
    
    
private:
    CameraImpl * _impl;
};