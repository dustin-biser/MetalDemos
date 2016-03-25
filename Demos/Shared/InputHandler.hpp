//
//  InputHandler.hpp
//  MetalDemos
//
//  Created by Dustin on 3/24/16.
//  Copyright © 2016 none. All rights reserved.
//

#pragma once

#include <functional>


// Forward Declaration
class InputHandlerImpl;



typedef std::function<void(void)> KeyCommand;

typedef std::function<void(float cursorDeltaX, float cursorDeltaY)> MouseMoveCommand;


class InputHandler {
public:
    /// Constructor
    InputHandler();
    
    /// Destructor
    ~InputHandler();
    
    void handleInput() const;
    
    void registerKeyCommand (
        char key,
        KeyCommand keyCommand
    );
    
    void registerMouseMoveCommand (
        MouseMoveCommand mouseMoveCommand
    );
    
    void keyDown(
        char key
    );
    
    void keyUp (
        char key
    );
    
    void mouseMoved (
        float cursorPositionX,
        float cursorPositionY
    );
    
    void mouseEntered (
        float cursorPositionX,
        float cursorPositionY
    );
    
    
private:
    InputHandlerImpl * _impl;

};