//
//  InputHandler.cpp
//  MetalDemos
//
//  Created by Dustin on 3/24/16.
//  Copyright © 2016 none. All rights reserved.
//

#include "InputHandler.hpp"


class InputHandlerImpl {
private:
    friend class InputHandler;
};



//---------------------------------------------------------------------------------------
InputHandler::InputHandler () {
    _impl = new InputHandlerImpl();
}


//---------------------------------------------------------------------------------------
InputHandler::~InputHandler() {
    delete _impl;
}