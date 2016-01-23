//
//  MetalViewController.swift
//
//  Created by Dustin on 12/30/15.
//  Copyright © 2015 none. All rights reserved.
//

import AppKit
import MetalKit


class MetalViewController: NSViewController {
    
    @IBOutlet weak var mtkView: MTKView!
    
    var metalRenderer : MetalRenderer! = nil
    
    
    //-----------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mtkView.delegate = self
        
        metalRenderer = MetalRenderer(withMTKView: mtkView)
    }
    
} // end class MetalViewController



extension MetalViewController : MTKViewDelegate {

    //-----------------------------------------------------------------------------------
    // Called whenever the drawableSize of the view will change
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        metalRenderer.reshape(size)
    }

    //-----------------------------------------------------------------------------------
    // Called on the delegate when it is asked to render into the view
    func drawInMTKView(view: MTKView) {
        autoreleasepool {
            metalRenderer.render()
        }
        
    }

}

