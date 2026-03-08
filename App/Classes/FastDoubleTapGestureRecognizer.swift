//
//  FastDoubleTapGestureRecognizer.swift
//  CiRCLES
//
//  Created by Antigravity on 2026/02/01.
//

import UIKit

class FastDoubleTapGestureRecognizer: UIGestureRecognizer {

    var tapDelay: TimeInterval = 0.2
    var singleTapHandler: (() -> Void)?

    private var firstTapTimestamp: TimeInterval = 0
    private var startPoint: CGPoint?

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        self.cancelsTouchesInView = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if touches.count != 1 {
            state = .failed
            return
        }

        if let touch = touches.first {
            startPoint = touch.location(in: view)
        }

        let now = Date().timeIntervalSince1970
        if firstTapTimestamp != 0 && (now - firstTapTimestamp < tapDelay) {
            state = .recognized
            firstTapTimestamp = 0
        } else {
            firstTapTimestamp = now
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first, let start = startPoint else { return }

        let current = touch.location(in: view)
        let distance = hypot(current.x - start.x, current.y - start.y)
        if distance > 10 {
            state = .failed
            firstTapTimestamp = 0
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)

        if state != .possible {
             return
        }

        let currentTimestamp = firstTapTimestamp
        guard currentTimestamp != 0 else { return }

        let deadline = currentTimestamp + tapDelay
        let delay = deadline - Date().timeIntervalSince1970

        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                // Only fire single tap if no second tap has started or been recognized in the meantime
                if self.state == .possible && self.firstTapTimestamp == currentTimestamp {
                    self.singleTapHandler?()
                    self.firstTapTimestamp = 0
                }
            }
        } else {
             if firstTapTimestamp != 0 {
                 singleTapHandler?()
                 firstTapTimestamp = 0
             }
             state = .failed
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        state = .failed
        firstTapTimestamp = 0
    }

    override func reset() {
        super.reset()
        firstTapTimestamp = 0
        startPoint = nil
    }
}
