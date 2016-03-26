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
     * @brief Translates Camera forward by the amount 'distance'.
     * @discussion The applied translation keeps the Camera at the same world space height,
     * while moving the camera forward.
     * If 'distance' is negative, the Camera is translated backward.
     */
    void moveForward (
        float distance
    );
    
    
    /*!
     * @brief Translates Camera to the side by an amount 'distance'.
     * @discussion Translations are applied with respect to the Camera's local vectors.
     * If 'distance' is positive the Camera is translated to the right.  Otherwise, if
     * 'distance' is negative, the Camera is translated to the left.
     */
    void strafe (
        float distance
    );
    
    
    /*!
     * @brief Translates Camera by raising it's position by an amount 'distance' in world
     * space.
     * @discussion  If 'distance' is negative, the Camera is lowered.
     */
    void elevate (
        float distance
    );
    
    
    /*!
     * @brief Rotates Camera 'angle' radians about 'axis' defined in world space
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
     * @brief Rotates Camera locally 'angle' radians about 'axis' defined in
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
    
    
    /*!
     * @brief Returns the world space forward direction of Camera.
     * @discussion This is different than the Camera's lookAt direction.  Moving the
     * Camera along it's forward direction will keep the Camera at a constant elevation
     * in world space regardless of where the Camera is currently looking.
     */
    glm::vec3 forwardDirection () const;
    
    
    /*!
     * @brief Convenience method for returning the negation of the forwardDirection.
     * @see Camera::forwardDirection()
     */
    glm::vec3 backDirection () const;
    
    
    /*!
     * @brief Returns the world space right-side direction of Camera.
     * @discussion Translating the Camera along its strafeRight direction will keep the
     * Camera at the same height elevation in world space regardless of the Camera's
     * orientation.
     */
    glm::vec3 strafeRightDirection() const;
    
    
    /*!
     * @brief Returns the world space left-side direction of Camera.
     * @discussion Translating the Camera along its strafeLeft direction will keep the
     * Camera at the same height elevation in world space regardless of the Camera's
     * orientation.
     */
    glm::vec3 strafeLeftDirection() const;
    
private:
    CameraImpl * _impl;
    
}; // end class Camera.