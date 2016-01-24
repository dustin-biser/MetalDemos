//
//  MetalViewController.swift
//
//  Created by Dustin on 1/23/16.
//  Copyright © 2016 none. All rights reserved.
//

import UIKit
import MetalKit

class MetalViewController: UIViewController {

    @IBOutlet weak var mtkView: MTKView!
    
    var metalRenderer : MetalRenderer! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make this MetalViewController the delegate of our MTKView.
        mtkView.delegate = self
        
        metalRenderer = MetalRenderer(withMTKView: mtkView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

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

