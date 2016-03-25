//
//  InputHandler.cpp
//  MetalDemos
//
//  Created by Dustin on 3/24/16.
//  Copyright © 2016 none. All rights reserved.
//

#include "InputHandler.hpp"
#include <unordered_map>
#include <cmath>
#include <glm/glm.hpp>


class InputHandlerImpl {
public:
    InputHandlerImpl();
    
private:
    friend class InputHandler;
    
    bool mouseCursorHasMoved();
    
    std::unordered_map<char, bool> isKeyDown;
    std::unordered_map<char, KeyCommand> keyCommands;
    
    // Mouse cursor position changes between frames, given in screen coordinates.
    float mouseDeltaX;
    float mouseDeltaY;
    
    MouseMoveCommand mouseMoveCommand;
};


//---------------------------------------------------------------------------------------
// InputHandlerImpl class methods
//---------------------------------------------------------------------------------------
InputHandlerImpl::InputHandlerImpl()
    : mouseDeltaX(0.0f),
      mouseDeltaY(0.0f)
{
    // Defualt mouse move command.
    mouseMoveCommand = [] (float, float) { };
}


//---------------------------------------------------------------------------------------
bool InputHandlerImpl::mouseCursorHasMoved() {
    const float epsilon(1.0e-6);
    return (std::abs(mouseDeltaX) > epsilon) || (std::abs(mouseDeltaY) > epsilon);
}






//---------------------------------------------------------------------------------------
// InputHandler class methods
//---------------------------------------------------------------------------------------
InputHandler::InputHandler () {
    _impl = new InputHandlerImpl();
}


//---------------------------------------------------------------------------------------
InputHandler::~InputHandler() {
    delete _impl;
}


//---------------------------------------------------------------------------------------
void InputHandler::registerKeyCommand (
    char key,
    KeyCommand keyCommand
) {
    _impl->keyCommands[key] = keyCommand;
}


//---------------------------------------------------------------------------------------
void InputHandler::registerMouseMoveCommand (
    MouseMoveCommand mouseMoveCommand
) {
    _impl->mouseMoveCommand = mouseMoveCommand;
}

//---------------------------------------------------------------------------------------
void InputHandler::handleInput() const
{
    // Handle key down events:
    for(auto pair : _impl->keyCommands) {
        char key = pair.first;
        if (_impl->isKeyDown[key]) {
            // Execute command regeistered for that key.
            _impl->keyCommands[key]();
        }
    }
    
    // Handle mouse move events:
    if (_impl->mouseCursorHasMoved()) {
        _impl->mouseMoveCommand(_impl->mouseDeltaX, _impl->mouseDeltaY);
    }
}


//---------------------------------------------------------------------------------------
void InputHandler::keyDown(char key) {
    _impl->isKeyDown[key] = true;
}


//---------------------------------------------------------------------------------------
void InputHandler::keyUp(char key) {
    _impl->isKeyDown[key] = false;
}

//---------------------------------------------------------------------------------------
void InputHandler::mouseMoved (
    int deltaX,
    int deltaY
){
    _impl->mouseDeltaX = float(deltaX);
    _impl->mouseDeltaY = float(deltaY);
}
