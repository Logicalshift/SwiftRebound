//
//  DemoView.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 15/07/2016.
//
//

import Foundation

///
/// Click/drag to move the circle
///
class DemoView : ReactiveView {
    override func drawReactive() {
        if leftMouseDown.value {
            // Draw an oval centered on the current position
            let clickPos    = mousePosition.value;
            let ovalRect    = NSInsetRect(NSRect(origin: clickPos, size: NSSize(width: 0, height: 0)), -64, -64);
            
            NSColor.blueColor().set();
            NSBezierPath.init(ovalInRect: ovalRect).fill();
        }
    }
}