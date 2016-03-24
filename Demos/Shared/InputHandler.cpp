//
//  InputHandler.cpp
//  MetalDemos
//
//  Created by Dustin on 3/24/16.
//  Copyright © 2016 none. All rights reserved.
//

#include "InputHandler.hpp"
#include <unordered_map>


class InputHandlerImpl {
private:
    friend class InputHandler;
    
    std::unordered_map<char, bool> isKeyDown;
    std::unordered_map<char, KeyCommand> keyCommands;
};


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
void InputHandler::handleInput() const
{
    for(auto pair : _impl->keyCommands) {
        char key = pair.first;
        if (_impl->isKeyDown[key]) {
            // Execute command regeistered for that key.
            _impl->keyCommands[key]();
        }
        
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
