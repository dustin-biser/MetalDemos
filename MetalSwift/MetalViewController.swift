//
//  ViewController.swift
//  MetalSwift
//
//  Created by Dustin on 12/30/15.
//  Copyright © 2015 none. All rights reserved.
//

import AppKit
import Metal
import MetalKit

private let numInflightCommandBuffers = 3

private let kTriangleVertices : [Float] = [
    -0.5, -0.5,  0.0,
     0.5, -0.5,  0.0,
     0.0,  0.5,  0.0
]

class MetalViewController: NSViewController, MTKViewDelegate {
    
    @IBOutlet weak var mtkView: MTKView!
    
    let device : MTLDevice! = MTLCreateSystemDefaultDevice()
    
    var commandQueue : MTLCommandQueue!     = nil
    var defaultShaderLibrary : MTLLibrary!  = nil
    var vertexBuffer : MTLBuffer!           = nil
    var pipelineState : MTLRenderPipelineState! = nil
    var depthState : MTLDepthStencilState! = nil

    //-----------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.setupView()
    }
    
    //-----------------------------------------------------------------------------------
    func setupView() {
        mtkView.delegate = self
        mtkView.device = device
    }
    
    //-----------------------------------------------------------------------------------
    // Called whenever the drawableSize of the view will change
    // MTKViewDelegate
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    //-----------------------------------------------------------------------------------
    // Called on the delegate when it is asked to render into the view
    // MTKViewDelegate
    func drawInMTKView(view: MTKView) {
        print("Draw Requested")
    }

}

