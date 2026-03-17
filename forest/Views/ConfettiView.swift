import SwiftUI
import UIKit

struct ConfettiEmitterView: UIViewRepresentable {
    var isActive: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard isActive else { return }
        emitConfetti(in: uiView)
    }

    private func emitConfetti(in view: UIView) {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: max(view.bounds.width, 1), height: 1)
        emitter.beginTime = CACurrentMediaTime()

        emitter.emitterCells = [
            makeCell(color: UIColor.systemYellow),
            makeCell(color: UIColor.systemOrange),
            makeCell(color: UIColor.systemPink),
            makeCell(color: UIColor.systemGreen),
            makeCell(color: UIColor.systemBlue),
            makeCell(color: UIColor.systemPurple)
        ]

        view.layer.addSublayer(emitter)

        // Stop emission quickly and remove after particles fall.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            emitter.birthRate = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            emitter.removeFromSuperlayer()
        }
    }

    private func makeCell(color: UIColor) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 10
        cell.lifetime = 3.0
        cell.velocity = 320
        cell.velocityRange = 140
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 3
        cell.yAcceleration = 420
        cell.xAcceleration = 0
        cell.spin = 3.5
        cell.spinRange = 4.0
        cell.scale = 0.06
        cell.scaleRange = 0.04
        cell.color = color.cgColor

        // A simple rectangle "confetti" particle.
        let size = CGSize(width: 14, height: 8)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setFillColor(UIColor.white.cgColor)
        ctx?.fill(CGRect(origin: .zero, size: size))
        cell.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        return cell
    }
}

