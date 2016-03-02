//
//  MetalView.swift
//  MetalSwift
//
//  Created by Dustin on 1/27/16.
//  Copyright © 2016 none. All rights reserved.
//

import MetalKit

class MetalView : MTKView {
    
#if os(OSX)
    override var acceptsFirstResponder : Bool { return true }
#endif
    
}
