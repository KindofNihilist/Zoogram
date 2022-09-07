//
//  MetalView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 16.02.2022.
//

import UIKit
import MetalKit
//import CoreGraphics
//import CoreImage

class MetalView: MTKView {
    
    //MARK: Metal Resources
    var defaultDevice: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var sourceTexture: MTLTexture!
    
    var context: CIContext! // 1
    var queue: MTLCommandQueue! // 2
    let colorSpace = CGColorSpaceCreateDeviceRGB() // 3
    var image: CIImage? { // 4
        didSet {
            drawCIImge()
        }
    }

    // 5
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        defaultDevice = MTLCreateSystemDefaultDevice()
        commandQueue = device?.makeCommandQueue()
        
        self.device = defaultDevice
        self.framebufferOnly = false
        
        context = CIContext(mtlDevice: defaultDevice)
        
        let loader = MTKTextureLoader(device: defaultDevice)
        
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func drawCIImge() {
        guard let image = image else { return }
        let drawable = currentDrawable!
        let buffer = queue.makeCommandBuffer()!
        // 6
        let widthScale = drawableSize.width / image.extent.width
        let heightScale = drawableSize.height / image.extent.height
        
        let scale = min(widthScale, heightScale)
        
        let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        let yPos = drawableSize.height / 2 - scaledImage.extent.height / 2
        
        let bounds = CGRect(x: 0, y: -yPos, width: drawableSize.width, height: drawableSize.height)
        
        // 7
        context.render(scaledImage,
                       to: drawable.texture,
                       commandBuffer: buffer,
                       bounds: bounds,
                       colorSpace: colorSpace)
        // 8
        buffer.present(drawable)
        buffer.commit()
        setNeedsDisplay()
    }
}
