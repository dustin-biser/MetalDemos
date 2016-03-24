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

class InputHandler {
public:
    /// Constructor
    InputHandler();
    
    /// Destructor
    ~InputHandler();
    
    void handleInput() const;
    
    void registerKeyCommand(char key, KeyCommand keyCommand);
    
    void keyDown(char key);
    
    void keyUp(char key);
    
    
private:
    InputHandlerImpl * _impl;

};