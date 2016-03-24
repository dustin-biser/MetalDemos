//
//  InputHandler.hpp
//  MetalDemos
//
//  Created by Dustin on 3/24/16.
//  Copyright © 2016 none. All rights reserved.
//

#pragma once


// Forward Declaration
class InputHandlerImpl;


class InputHandler {
public:
    /// Constructor
    InputHandler();
    
    /// Destructor
    ~InputHandler();
    
    
//    registerKeyCommand(InputKey key, InputKeyCommand command);
    
private:
    InputHandlerImpl * _impl;

};