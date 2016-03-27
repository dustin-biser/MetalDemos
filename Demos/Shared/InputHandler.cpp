//
//  InputHandler.cpp
//  MetalDemos
//
//  Created by Dustin on 3/24/16.
//  Copyright © 2016 none. All rights reserved.
//

#include "InputHandler.hpp"
#include <map>
#include <cmath>
#include <glm/glm.hpp>


class InputHandlerImpl {
public:
    InputHandlerImpl();
    
private:
    friend class InputHandler;
    
    bool mouseCursorHasMoved();
    
    std::map<InputKey, bool> isKeyDown;
    std::map<InputKey, KeyCommand> keyCommands;
    
    // Mouse cursor position changes between frames, given in screen coordinates.
    float mouseDeltaX;
    float mouseDeltaY;
    
    MouseMoveCommand mouseMoveCommand;
};


//---------------------------------------------------------------------------------------
// InputHandlerImpl methods
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
    return (std::abs(mouseDeltaX) > FLT_EPSILON) || (std::abs(mouseDeltaY) > FLT_EPSILON);
}





//---------------------------------------------------------------------------------------
// InputHandler methods
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
    InputKey key,
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
        InputKey key = pair.first;
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
void InputHandler::keyDown (
    unsigned short keyCode
) {
    InputKey inputKey = static_cast<InputKey>(keyCode);
    _impl->isKeyDown[inputKey] = true;
}


//---------------------------------------------------------------------------------------
void InputHandler::keyUp (
    unsigned short keyCode
) {
    InputKey inputKey = static_cast<InputKey>(keyCode);
    _impl->isKeyDown[inputKey] = false;
}

//---------------------------------------------------------------------------------------
void InputHandler::mouseMoved (
    int deltaX,
    int deltaY
){
    _impl->mouseDeltaX = float(deltaX);
    _impl->mouseDeltaY = float(deltaY);
}
