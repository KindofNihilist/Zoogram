//
//  MetalView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 16.02.2022.
//

import UIKit
import MetalKit

class MetalView: MTKView {

    // MARK: Metal Resources
    var defaultDevice: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var sourceTexture: MTLTexture!

    var context: CIContext!
    var queue: MTLCommandQueue!
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var image: CIImage? {
        didSet {
            drawCIImge()
        }
    }

    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        defaultDevice = MTLCreateSystemDefaultDevice()
        commandQueue = device?.makeCommandQueue()
        self.device = defaultDevice
        self.framebufferOnly = false
        context = CIContext(mtlDevice: defaultDevice)
//        let loader = MTKTextureLoader(device: defaultDevice)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func drawCIImge() {
        guard let image = image else { return }
        let drawable = currentDrawable!
        let buffer = queue.makeCommandBuffer()!

        let widthScale = drawableSize.width / image.extent.width
        let heightScale = drawableSize.height / image.extent.height

        let scale = min(widthScale, heightScale)

        let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let yPos = drawableSize.height / 2 - scaledImage.extent.height / 2

        let bounds = CGRect(x: 0, y: -yPos, width: drawableSize.width, height: drawableSize.height)

        context.render(scaledImage,
                       to: drawable.texture,
                       commandBuffer: buffer,
                       bounds: bounds,
                       colorSpace: colorSpace)
        buffer.present(drawable)
        buffer.commit()
        setNeedsDisplay()
    }
}
