//
//  MetalViewController.swift
//  MetalTriangle-iOS
//
//  Created by Dustin on 1/22/16.
//  Copyright © 2016 none. All rights reserved.
//

import UIKit
import MetalKit


/// Mode to use for multi-buffered rendering.
enum MultiBufferMode : Int {
    case SingleBuffer = 1
    case DoubleBuffer
    case TripleBuffer
}


class DemoBase : UIViewController {
    
    @IBOutlet var mtkView: MetalView!
    
    var device : MTLDevice! = nil
    var commandQueue : MTLCommandQueue! = nil
    var defaultShaderLibrary : MTLLibrary! = nil
    
    //-- For Multi-Buffering rendered frames
    private var multiBufferMode = MultiBufferMode.SingleBuffer
    var numBufferedFrames : Int {
        get {
            return multiBufferMode.rawValue
        }
    }
    private var inflightSemaphore : dispatch_semaphore_t! = nil
    
    
    //-----------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupMetal()
        
        // This class will handle drawing to the MTKView
        mtkView.delegate = self
        
        mtkView.device = device
        mtkView.preferredFramesPerSecond = 60
        
        inflightSemaphore = dispatch_semaphore_create(numBufferedFrames)
    }
    
    //-----------------------------------------------------------------------------------
    private func setupMetal() {
        device = MTLCreateSystemDefaultDevice()
        if (device == nil) {
            fatalError("Error creating default MTLDevice.")
        }
    
        defaultShaderLibrary = device.newDefaultLibrary()
        if (defaultShaderLibrary == nil) {
            fatalError("Error creating default shader library.\n" +
                "Check that a .metal file has been added to the target's Compile Sources list.")
        }
        
        commandQueue = device.newCommandQueue()
    }
    
    //-----------------------------------------------------------------------------------
    func setMultiBufferMode(mode : MultiBufferMode) {
        if mode != self.multiBufferMode {
            inflightSemaphore = dispatch_semaphore_create(numBufferedFrames)
        }
    }
    
    //-----------------------------------------------------------------------------------
    /**
     Called once per frame to perform rendering to this class's MTKView.
     - parameter commandBuffer: Used to encode render commands into.
    */
    func draw(commandBuffer : MTLCommandBuffer) {
        
    }
    
    //-----------------------------------------------------------------------------------
    /// Called once the size of the MTKView changes.
    func viewSizeChanged(view: MTKView, newSize: CGSize) {
    
    }

    //-----------------------------------------------------------------------------------
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

} // end class MetalViewController



extension DemoBase : MTKViewDelegate {

    //-----------------------------------------------------------------------------------
    // Called whenever the drawableSize of the view will change
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        self.viewSizeChanged(mtkView, newSize: size)
    }

    //-----------------------------------------------------------------------------------
    // Called on the delegate when it is asked to render into the view
    func drawInMTKView(view: MTKView) {
        autoreleasepool {
            // Preflight frames on the CPU (using a semaphore as a guard) and commit them
            // to the GPU.  This semaphore will get signaled once the GPU completes a
            // frame's work via addCompletedHandler callback below, signifying the CPU
            // can go ahead and prepare another frame.
            dispatch_semaphore_wait(inflightSemaphore, DISPATCH_TIME_FOREVER);
            
            let commandBuffer = commandQueue.commandBuffer()
            
            // Tell the derived class to encode commands into the commandBuffer.
            self.draw(commandBuffer)
            
            commandBuffer.presentDrawable(mtkView.currentDrawable!)
            
            // Once GPU has completed executing the commands within this buffer, signal
            // the semaphore and allow the CPU to proceed in constructing the next frame.
            commandBuffer.addCompletedHandler() { buffer in
                dispatch_semaphore_signal(self.inflightSemaphore)
            }
            
            // Push command buffer to GPU for execution.
            commandBuffer.commit()
        }
    }

}

