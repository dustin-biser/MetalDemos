//
//  Camera.cpp
//  MetalDemos
//
//  Created by Dustin on 3/16/16.
//  Copyright © 2016 none. All rights reserved.
//

#include "Camera.hpp"

#include <glm/gtc/matrix_transform.hpp>


class CameraImpl {
private:
    friend class Camera;
    
    // Constructed as identity matrix.
    glm::mat4 projectionMatrix;
    
    // Constructed as identity matrix.
    glm::mat4 viewMatrix;
    
    // World space position
    glm::vec3 position;
};


//---------------------------------------------------------------------------------------
Camera::Camera() {
    _impl = new CameraImpl();
}

//---------------------------------------------------------------------------------------
Camera::~Camera() {
    delete _impl;
}

//---------------------------------------------------------------------------------------
void Camera::lookAt (
    const glm::vec3 & cameraPosition,
    const glm::vec3 & focusPosition,
    const glm::vec3 & upDirection
) {
    _impl->position = cameraPosition;
    _impl->viewMatrix = glm::lookAt(cameraPosition, focusPosition, upDirection);
}
    

//---------------------------------------------------------------------------------------
glm::mat4 Camera::viewMatrix() const {
    return _impl->viewMatrix;
}

//---------------------------------------------------------------------------------------
glm::vec3 Camera::position() const {
    return _impl->position;
}

//---------------------------------------------------------------------------------------
void Camera::translate (
    const glm::vec3 & vec
) {
    CameraImpl & cameraImpl = *_impl;
    cameraImpl.position += vec;
    (cameraImpl.viewMatrix)[3] -= glm::vec4(vec, 0.0f);
}

//---------------------------------------------------------------------------------------
void Camera::rotate (
    const float angle,
    const glm::vec3 & axis
) {
    glm::mat4 * viewMatrix = &_impl->viewMatrix;
    *viewMatrix = glm::rotate(glm::mat4(), -angle, axis) * (*viewMatrix);
    
}