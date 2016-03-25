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
    
    float cursorDeltaX();
    
    float cursorDeltaY();
    
    bool mouseCursorHasMoved();
    
    std::unordered_map<char, bool> isKeyDown;
    std::unordered_map<char, KeyCommand> keyCommands;
    
    // Mouse cursor screen coordinates
    glm::vec2 prevCursorPosition;
    glm::vec2 currentCursorPosition;
    
    MouseMoveCommand mouseMoveCommand;
};


//---------------------------------------------------------------------------------------
// InputHandlerImpl class methods
//---------------------------------------------------------------------------------------
InputHandlerImpl::InputHandlerImpl()
    : prevCursorPosition(0.0f),
      currentCursorPosition(0.0f)
{
    // Defualt mouse move command.
    mouseMoveCommand = [] (float, float) { };
}

//---------------------------------------------------------------------------------------
float InputHandlerImpl::cursorDeltaX() {
    return currentCursorPosition.x - prevCursorPosition.x;
}

//---------------------------------------------------------------------------------------
float InputHandlerImpl::cursorDeltaY() {
    return currentCursorPosition.y - prevCursorPosition.y;
}


//---------------------------------------------------------------------------------------
bool InputHandlerImpl::mouseCursorHasMoved() {
    const float epsilon(1.0e-6);
    return (std::abs(cursorDeltaX()) > epsilon) || (std::abs(cursorDeltaY()) > epsilon);
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
        const float cursorDeltaX = _impl->cursorDeltaX();
        const float cursorDeltaY = _impl->cursorDeltaY();
        _impl->mouseMoveCommand(cursorDeltaX, cursorDeltaY);
        
        _impl->prevCursorPosition = _impl->currentCursorPosition;
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
    float cursorPositionX,
    float cursorPositionY
){
    // Save previous cursor location.
    _impl->prevCursorPosition = _impl->currentCursorPosition;
    
    // Set new cursor location.
    _impl->currentCursorPosition.x = cursorPositionX;
    _impl->currentCursorPosition.y = cursorPositionY;
}

//---------------------------------------------------------------------------------------
void InputHandler::mouseEntered (
    float cursorPositionX,
    float cursorPositionY
) {
    //-- Reset previous and current cursor positions:
    _impl->prevCursorPosition.x = cursorPositionX;
    _impl->prevCursorPosition.y = cursorPositionY;
    _impl->currentCursorPosition = _impl->prevCursorPosition;
}