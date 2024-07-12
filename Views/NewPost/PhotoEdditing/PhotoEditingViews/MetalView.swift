//
//  MetalView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 16.02.2022.
//

import UIKit
import MetalKit

@MainActor
protocol ImageMetalPreviewDelegate: AnyObject {
    func getImageToRender() -> CIImage?
}

class ImageMetalPreview: MTKView, MTKViewDelegate {

    weak var previewDelegate: ImageMetalPreviewDelegate?

    var defaultDevice: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var sourceTexture: MTLTexture!
    let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()

    var isWidthDominant: Bool!
    var ratio: CGFloat!
    var context: CIContext!

    init(image: UIImage) {
        super.init(frame: CGRect.zero, device: .none)
        setupMetalPreview(for: image)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupMetalPreview(for image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 1) else {
            print("Couldn't convert chosen image to Data")
            return
        }
        defaultDevice = MTLCreateSystemDefaultDevice()
        context = CIContext(mtlDevice: defaultDevice)
        commandQueue = defaultDevice.makeCommandQueue()
        isWidthDominant = image.isWidthDominant()
        ratio = image.ratio()
        device = defaultDevice
        delegate = self
        framebufferOnly = false

        let loader = MTKTextureLoader(device: defaultDevice)
        do {
            sourceTexture = try loader.newTexture(data: imageData)
        } catch {
            print("Couldn't create a texture with chosen image")
        }
    }

    private func createScaledImage(image: CIImage, originY: CGFloat, originX: CGFloat, scale: CGFloat) -> CIImage {
#if targetEnvironment(simulator)
        let originY = originY < 0 ? 0 : originY
        let transformedPosition = CGAffineTransform(translationX: originX, y: originY)
        let transformedScale = CGAffineTransform(scaleX: scale, y: scale)
        return image
            .transformed(by: transformedScale)
            .transformed(by: transformedPosition)
#else
        let originY = originY < 0 ? 0 : originY
        let originX = originX < 0 ? 0 : originX
        let transformedPosition = CGAffineTransform(translationX: originX, y: originY)
        let transformedScale = CGAffineTransform(scaleX: scale, y: scale)
        return image
            .transformed(by: transformedScale)
            .transformed(by: transformedPosition)
#endif
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let currentDrawable = view.currentDrawable,
              let sourceTexture = self.sourceTexture,
              let commandBuffer = self.commandQueue.makeCommandBuffer(),
              let inputImage = CIImage(mtlTexture: sourceTexture),
              let imageToRender = self.previewDelegate?.getImageToRender()
        else { return }

        let bounds = CGRect(x: 0, y: 0, width: view.drawableSize.width, height: view.drawableSize.height)

        let scaleX = view.drawableSize.width / inputImage.extent.width
        let scaleY = view.drawableSize.height / inputImage.extent.height
        var scale: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
        var imageOriginYPoint: CGFloat = 0
        var imageOriginXPoint: CGFloat = 0

        scale = (scaleY > scaleX) ? scaleX : scaleY

        width = inputImage.extent.width * scale
        height = inputImage.extent.height * scale

        if isWidthDominant {
            imageOriginYPoint = (bounds.maxY - height) / 2
        } else {
            imageOriginXPoint = (bounds.maxX - width) / 2
        }

        let originX = (bounds.minX + imageOriginXPoint)
        let originY = (bounds.minY + imageOriginYPoint)

        let scaledImage = createScaledImage(image: imageToRender,
                                            originY: originY,
                                            originX: originX,
                                            scale: scale)

        context.render(scaledImage,
                       to: currentDrawable.texture,
                       commandBuffer: commandBuffer,
                       bounds: bounds,
                       colorSpace: colorSpace)
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
}
