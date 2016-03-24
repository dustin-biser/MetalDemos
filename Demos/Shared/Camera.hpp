//
//  Camera.hpp
//  MetalDemos
//
//  Created by Dustin on 3/16/16.
//  Copyright © 2016 none. All rights reserved.
//

#pragma once

#include <glm/glm.hpp>


// Forward Declaration
class CameraImpl;

/*!
 * @brief A class for encapsulating both a projection matrix and view matrix.
 * @discussion A Camera defines it's basis vectors using a right-handed coordinates
 * system.
 */
class Camera {
public:
    /// Constructor
    Camera (
        float fovy,
        float aspect,
        float nearPlaneDistance,
        float farPlaneDistance
    );
    
    
    /// Destructor
    ~Camera ();
    
    
    /*!
     * @brief Orientates and positions and the Camera.
     */
    void lookAt (
        const glm::vec3 & cameraPosition,
        const glm::vec3 & focusPosition,
        const glm::vec3 & upDirection
    );
    
    
    /*!
     * @brief Returns the projection matrix of the Camera.
     */
    glm::mat4 projectionMatrix () const;
    
    
    /*!
     * @brief Returns the view matrix of the Camera.
     */
    glm::mat4 viewMatrix () const;
    
    
    /*!
     * @return the world space position of Camera.
     */
    glm::vec3 position () const;
    
    
    /*!
     * @brief Translates Camera with respect to world space coordinates.
     */
    void translate (
        const glm::vec3 & vec
    );
    
    
    /*!
     * @brief Translates Camera locally with respect to eye space coordinates.
     */
    void translateLocal (
        const glm::vec3 & vec
    );
    
    
    /*!
     * @brief Rotates Camera 'angle' randians about 'axis' defined in world space
     * coordinates.
     *
     * @param angle Given in radians.
     * @param axis Given world space coordinates.
     */
    void rotate (
        float angle,
        const glm::vec3 & axis
    );
    
    
    /*!
     * @brief Rotates Camera locally 'angle' randians about 'axis' defined in
     * eye space coordinates.
     *
     * @param angle Given in radians.
     * @param axis Given in eye space coordinates.
     */
    void rotateLocal (
        float angle,
        const glm::vec3 & axis
    );
    
    
    /*!
     * @brief Rotates Camera 'angle' radians about it's local z-axis.
     * @param angle Given in radians.
     */
    void roll (
        float angle
    );
    
    
    /*!
     * @brief Rotates Camera 'angle' radians about it's local x-axis.
     * @param angle Given in radians.
     */
    void pitch (
        float angle
    );
    
    
    /*!
     * @brief Rotates Camera 'angle' radians about it's local y-axis.
     * @param angle Given in radians.
     */
    void yaw (
        float angle
    );
    
    
private:
    CameraImpl * _impl;
    
}; // end class Camera.