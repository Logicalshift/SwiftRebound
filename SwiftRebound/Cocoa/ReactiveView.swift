//
//  ReactiveView.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 15/07/2016.
//
//

import Cocoa

public class ReactiveView : NSView {
    /// Trigger for the drawReactive() call
    private var _drawTrigger: Optional<() -> ()> = nil;
    
    /// Lifetime of the drawReactive() call
    private var _drawLifetime: Lifetime? = nil;
    
    override public func drawRect(dirtyRect: NSRect) {
        if let trigger = _drawTrigger {
            // Call the existing trigger
            trigger();
        } else {
            // Create a new trigger
            let (trigger, lifetime) = Binding.trigger({
                self.drawReactive();
            }, causeUpdate: {
                self.setNeedsDisplayInRect(self.bounds);
            });
            
            _drawTrigger    = trigger;
            _drawLifetime   = lifetime;
            
            trigger();
        }
    }
    
    ///
    /// Should be overridden by subclasses; draws this view
    ///
    /// Any SwiftRebound values used here will be monitored and an update will be triggered if they change
    ///
    public func drawReactive() {
        // Implement in subclasses
    }
}