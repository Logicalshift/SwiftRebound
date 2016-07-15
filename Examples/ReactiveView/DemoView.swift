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
    let clickPosition = Binding.create(NSPoint(x: 0, y:0));
    
    override func mouseDown(theEvent: NSEvent) {
        clickPosition.value = convertPoint(theEvent.locationInWindow, fromView: nil);
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        clickPosition.value = convertPoint(theEvent.locationInWindow, fromView: nil);
    }
    
    override func drawReactive() {
        // Draw an oval centered on the current position
        let clickPos    = clickPosition.value;
        let ovalRect    = NSInsetRect(NSRect(origin: clickPos, size: NSSize(width: 0, height: 0)), -64, -64);
        
        NSColor.blueColor().set();
        NSBezierPath.init(ovalInRect: ovalRect).fill();
    }
}