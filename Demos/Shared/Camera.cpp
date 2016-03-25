//
//  Camera.cpp
//  MetalDemos
//
//  Created by Dustin on 3/16/16.
//  Copyright © 2016 none. All rights reserved.
//

#include "Camera.hpp"

#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtx/quaternion.hpp>


class CameraImpl {
private:
    friend class Camera;
    
    // Constructed as identity matrix.
    glm::mat4 projectionMatrix;
    
    // World space position.
    glm::vec3 position;
    
    // Camera basis vectors given in World Space Coordinates.
    glm::vec3 back;   // +z direction
    glm::vec3 up;     // +y direction
    glm::vec3 right;  // +x direction
};


//---------------------------------------------------------------------------------------
Camera::Camera (
    float fovy,
    float aspect,
    float nearPlaneDistance,
    float farPlaneDistance
) {
    _impl = new CameraImpl();
    
    _impl->projectionMatrix =
        glm::perspective(fovy, aspect, nearPlaneDistance, farPlaneDistance);
}


//---------------------------------------------------------------------------------------
Camera::~Camera () {
    delete _impl;
}


//---------------------------------------------------------------------------------------
void Camera::lookAt (
    const glm::vec3 & cameraPosition,
    const glm::vec3 & focusPosition,
    const glm::vec3 & upDirection
) {
    _impl->position = cameraPosition;
    
    // Construct an orthonormal basis for the Camera axes:
    _impl->back = glm::normalize(cameraPosition - focusPosition);
    _impl->right = glm::normalize(glm::cross(upDirection, _impl->back));
    _impl->up = glm::cross(_impl->back, _impl->right);
}

//---------------------------------------------------------------------------------------
glm::mat4 Camera::projectionMatrix () const {
    return _impl->projectionMatrix;
}
    

//---------------------------------------------------------------------------------------
glm::mat4 Camera::viewMatrix () const {
    glm::mat4 viewMatrix;
    
    viewMatrix[0] = glm::vec4(_impl->right, 0.0f);
    viewMatrix[1] = glm::vec4(_impl->up, 0.0f);
    viewMatrix[2] = glm::vec4(_impl->back, 0.0f);
    viewMatrix = glm::transpose(viewMatrix);
    
    glm::mat4 & m = viewMatrix;
    glm::vec3 p = -1.0f * _impl->position;
    viewMatrix[3] = (m[0] * p.x) + (m[1] * p.y) + (m[2] * p.z) + m[3];
    
    return viewMatrix;
}


//---------------------------------------------------------------------------------------
glm::vec3 Camera::position() const {
    return _impl->position;
}


//---------------------------------------------------------------------------------------
void Camera::translate (
    const glm::vec3 & vec
) {
    _impl->position += vec;
}


//---------------------------------------------------------------------------------------
void Camera::translateLocal (
    const glm::vec3 & vec
) {
    _impl->position += (_impl->right * vec.x) +
                       (_impl->up * vec.y) +
                       (_impl->back * vec.z);
}


//---------------------------------------------------------------------------------------
void Camera::moveForward (
    float distance
) {
    glm::vec3 upWorld = glm::vec3(0.0f, 1.0f, 0.0f);
    glm::vec3 a = glm::dot(_impl->back, upWorld) * upWorld;
    glm::vec3 forward = -1.0f * glm::normalize(_impl->back - a);
    
    this->translate(forward * distance);
}


//---------------------------------------------------------------------------------------
void Camera::strafe (
    float distance
) {
    this->translateLocal(glm::vec3(distance, 0.0f, 0.0f));
}
                         
                         
//---------------------------------------------------------------------------------------
void Camera::elevate (
    float distance
) {
    this->translateLocal(glm::vec3(0.0f, distance, 0.0f));
}

                         
//---------------------------------------------------------------------------------------
void Camera::rotate (
    float angle,
    const glm::vec3 & axis
) {
    glm::quat q = glm::angleAxis(angle, axis);
    
    _impl->right = glm::rotate(q, _impl->right);
    _impl->up = glm::rotate(q, _impl->up);
    _impl->back = glm::rotate(q, _impl->back);
}

                         
//---------------------------------------------------------------------------------------
void Camera::rotateLocal (
    float angle,
    const glm::vec3 & axis
) {
    // Convert eye space axis to world space.
    glm::vec3 axisWorldSpace =
        (axis.x * _impl->right) + (axis.y * _impl->up) + (axis.z * _impl->back);
    
    // Then rotate about Camera's basis vectors about axisWorldSpace.
    this->rotate(angle, axisWorldSpace);
}

                         
//---------------------------------------------------------------------------------------
void Camera::roll (
    float angle
) {
    // Local z-axis given in eye space coordinates.
    glm::vec3 localZ(0.0f, 0.0f, 1.0f);
    
    this->rotateLocal(angle, localZ);
}

                         
//---------------------------------------------------------------------------------------
void Camera::pitch (
    float angle
) {
    // Local x-axis given in eye space coordinates.
    glm::vec3 localX(1.0f, 0.0f, 0.0f);
    
    this->rotateLocal(angle, localX);
}

                         
//---------------------------------------------------------------------------------------
void Camera::yaw (
    float angle
) {
    // Local y-axis given in eye space coordinates.
    glm::vec3 localY(0.0f, 1.0f, 0.0f);
    
    this->rotateLocal(angle, localY);
}