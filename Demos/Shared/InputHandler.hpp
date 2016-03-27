//
//  InputHandler.hpp
//  MetalDemos
//
//  Created by Dustin on 3/24/16.
//  Copyright © 2016 none. All rights reserved.
//

#pragma once

#include <functional>


//-- Forward Declarations:
class InputHandlerImpl;
enum class InputKey : unsigned short;


//-- Command Types:
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
        InputKey key,
        KeyCommand keyCommand
    );
    
    
    void registerMouseMoveCommand (
        MouseMoveCommand mouseMoveCommand
    );
    
    
    /*!
     * @brief Used to capture the OS depenent key code of a key down event.
     */
    void keyDown(
        unsigned short keyCode
    );
    
    
    /*!
     * @brief Used to capture the OS depenent key code of a key up event.
     */
    void keyUp (
        unsigned short keyCode
    );
    
    
    /*!
     * @brief Used to capture mouse cursor deltas between frames.
     */
    void mouseMoved (
        int deltaX,
        int deltaY
    );
    
private:
    InputHandlerImpl * _impl;

};


#if defined(__APPLE__)
enum class InputKey : unsigned short {
    A      = 0,
    S      = 1,
    D      = 2,
    F      = 3,
    H      = 4,
    G      = 5,
    Z      = 6,
    X      = 7,
    C      = 8,
    V      = 9,
    B      = 11,
    Q      = 12,
    W      = 13,
    E      = 14,
    R      = 15,
    Y      = 16,
    T      = 17,
    NUM_1  = 18,
    NUM_2  = 19,
    NUM_3  = 20,
    NUM_4  = 21,
    NUM_6  = 22,
    NUM_5  = 23,
    EQUALS = 24,
    NUM_9  = 25,
    NUM_7  = 26,
    MINUS  = 27,
    NUM_8  = 28,
    NUM_0  = 29,
    O      = 31,
    U      = 32,
    I      = 34,
    P      = 35,
    J      = 38,
    RETURN = 36,
    L      = 37,
    K      = 40,
    N      = 45,
    M      = 46,
    TAB    = 48
};
#endif