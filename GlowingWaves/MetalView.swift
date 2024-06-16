//
//  MetalView.swift
//  GlowingWaves
//
//  Created by Grisha Tadevosyan on 16.06.24.
//

import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60

        mtkView.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        mtkView.isOpaque = false
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalView
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!

        var startTime: CFAbsoluteTime!

        init(_ parent: MetalView) {
            self.parent = parent
            super.init()

            self.device = MTLCreateSystemDefaultDevice()
            self.commandQueue = self.device.makeCommandQueue()
            self.pipelineState = buildPipelineState(device: self.device)
            self.startTime = CFAbsoluteTimeGetCurrent()
        }

        func buildPipelineState(device: MTLDevice) -> MTLRenderPipelineState {
            let library = device.makeDefaultLibrary()!
            let vertexFunction = library.makeFunction(name: "vertexShader")
            let fragmentFunction = library.makeFunction(name: "fragmentShader")

            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

            return try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor else { return }

            let commandBuffer = commandQueue.makeCommandBuffer()!
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!

            renderEncoder.setRenderPipelineState(pipelineState)

            var time = Float(CFAbsoluteTimeGetCurrent() - self.startTime)
            var resolution = vector_float2(Float(view.drawableSize.width), Float(view.drawableSize.height))

            renderEncoder.setVertexBytes(&resolution, length: MemoryLayout<vector_float2>.size, index: 1)
            renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)

            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
