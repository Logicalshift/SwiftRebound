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
    
    /// Lifetime of the observer that updates the tracking rectangle
    private var _trackingObserverLifetime: Lifetime?;
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect);
        
        setupObservers();
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder);
        
        setupObservers();
    }
    
    deinit {
        _drawLifetime?.done();
        _trackingObserverLifetime?.done();
    }
    
    private var _isDrawing = false;
    
    override public func drawRect(dirtyRect: NSRect) {
        _isDrawing = true;
        
        if let trigger = _drawTrigger {
            // Call the existing trigger
            trigger();
        } else {
            // Create a new trigger
            let (trigger, lifetime) = Binding.trigger({ [unowned self] in
                self.drawReactive();
            }, causeUpdate: { [unowned self] in
                if !self._isDrawing {
                    self.triggerRedraw();
                } else {
                    NSRunLoop.currentRunLoop().performSelector(#selector(ReactiveView.triggerRedraw), target: self, argument: nil, order: 0, modes: [NSDefaultRunLoopMode]);
                }
            });
            
            _drawTrigger    = trigger;
            _drawLifetime   = lifetime;
            
            trigger();
        }
        
        _isDrawing = false;
    }
    
    public func triggerRedraw() {
        self.setNeedsDisplayInRect(self.bounds);
    }
    
    ///
    /// Should be overridden by subclasses; draws this view
    ///
    /// Any SwiftRebound values used here will be monitored and an update will be triggered if they change
    ///
    public func drawReactive() {
        // Implement in subclasses
    }
    
    /// The position of the mouse over this view
    public let mousePosition = Binding.create(NSPoint(x: 0, y: 0));
    
    /// True if the mouse is over this view
    public let mouseOver = Binding.create(false);
    
    /// The pressure used by the stylus over this view
    public let pressure = Binding.create(Float(0.0));
    
    /// True if any mouse button is down
    public let anyMouseDown = Binding.create(false);
    
    /// True if the left mouse button has been clicked over this view
    public let leftMouseDown = Binding.create(false);
    
    /// True if the right mouse button has been clicked over this view
    public let rightMouseDown = Binding.create(false);
    
    ///
    /// Updates mouse properties for this view from an event
    ///
    private func updateMouseProperties(event: NSEvent) {
        // Read from the event
        let newMousePos = convertPoint(event.locationInWindow, fromView: nil);
        var leftDown    = self.leftMouseDown.value;
        var rightDown   = self.rightMouseDown.value;
        let pressure    = event.pressure;
        
        switch (event.type) {
        case NSEventType.LeftMouseDown:     leftDown = true; break;
        case NSEventType.LeftMouseUp:       leftDown = false; break;
        case NSEventType.RightMouseDown:    rightDown = true; break;
        case NSEventType.RightMouseUp:      rightDown = false; break;
        default:                            break;
        }
        
        let anyDown     = leftDown || rightDown;
        
        // Update the properties
        if newMousePos != self.mousePosition.value {
            self.mousePosition.value = newMousePos;
        }
        
        if leftDown != self.leftMouseDown.value {
            self.leftMouseDown.value = leftDown;
        }
        
        if rightDown != self.rightMouseDown.value {
            self.rightMouseDown.value = rightDown;
        }
        
        if anyDown != self.anyMouseDown.value {
            self.anyMouseDown.value = anyDown;
        }
        
        if pressure != self.pressure.value {
            self.pressure.value = pressure;
        }
    }
    
    override public func mouseDown(theEvent: NSEvent)           { updateMouseProperties(theEvent); }
    override public func mouseUp(theEvent: NSEvent)             { updateMouseProperties(theEvent); }
    override public func mouseDragged(theEvent: NSEvent)        { updateMouseProperties(theEvent); }
    override public func rightMouseDown(theEvent: NSEvent)      { updateMouseProperties(theEvent); }
    override public func rightMouseUp(theEvent: NSEvent)        { updateMouseProperties(theEvent); }
    override public func rightMouseDragged(theEvent: NSEvent)   { updateMouseProperties(theEvent); }
    override public func otherMouseDown(theEvent: NSEvent)      { updateMouseProperties(theEvent); }
    override public func otherMouseUp(theEvent: NSEvent)        { updateMouseProperties(theEvent); }
    override public func otherMouseDragged(theEvent: NSEvent)   { updateMouseProperties(theEvent); }
    override public func mouseMoved(theEvent: NSEvent)          { updateMouseProperties(theEvent); }
    
    override public func mouseEntered(theEvent: NSEvent) {
        if !self.mouseOver.value {
            self.mouseOver.value        = true;
            self.mousePosition.value    = self.convertPoint(theEvent.locationInWindow, fromView: nil);
        }
    }
    override public func mouseExited(theEvent: NSEvent)         { if mouseOver.value { mouseOver.value = false; } }
    
    ///
    /// Sets up the observers for this view
    ///
    private func setupObservers() {
        // TODO: currently keeping this in memory causes a self-reference (our 'keep self while binding active' policy causing us issues, I think)
        let bounds = self.bindKeyPath("frame");
        
        // Computed that works out whether or not we need a tracking rectangle
        enum NeedsTracking {
            case KeepTracking
            case NeedTracking
            case TrackEnterExitOnly
            case NoTracking
        }
        
        let needsTracking = Binding.computed({ [unowned self] () -> NeedsTracking in
            // If something is observing the mouse position...
            if self.mousePosition.isBound.value {
                if !self.anyMouseDown.value {
                    // Need to track the mouse if the mouse isn't clicked (we get positions anyway if it is down)
                    return NeedsTracking.NeedTracking;
                } else if !self.mouseOver.isBound.value {
                    // Leave the tracking as what it was if the mouse is clicked
                    return NeedsTracking.KeepTracking;
                }
            }
 
            // If something is observing whether or not we're over the window, then track only enter/exits
            if self.mouseOver.isBound.value {
                return NeedsTracking.TrackEnterExitOnly;
            }
            
            // Don't need tracking otherwise
            return NeedsTracking.NoTracking;
        });
        
        // Tracking bounds tracks whether or not we need a tracking rectangle and whether or not it's active
        let trackingBounds = Binding.computed({ () -> (NSRect, NeedsTracking) in
            let boundsValue = bounds.value as! NSValue;
            let boundsRect  = boundsValue.rectValue;
            return (boundsRect, needsTracking.value);
        });
        
        // Add or remove a tracking rectangle if needsTracking changes or the size of the view changes
        var tracking: NSTrackingArea?;
        
        _trackingObserverLifetime = trackingBounds.observe({ [unowned self] (bounds, needsTracking) in
            switch needsTracking {
            case NeedsTracking.KeepTracking: break;
                
            case NeedsTracking.NeedTracking:
                if let tracking = tracking { self.removeTrackingArea(tracking); }

                let newTracking = NSTrackingArea(rect: bounds, options: NSTrackingAreaOptions.MouseMoved.union(NSTrackingAreaOptions.MouseEnteredAndExited).union(NSTrackingAreaOptions.ActiveInKeyWindow), owner: self, userInfo: nil);
                tracking = newTracking;
                self.addTrackingArea(newTracking);
                break;
                
            case NeedsTracking.TrackEnterExitOnly:
                if let tracking = tracking { self.removeTrackingArea(tracking); }
                
                let newTracking = NSTrackingArea(rect: bounds, options: NSTrackingAreaOptions.MouseEnteredAndExited.union(NSTrackingAreaOptions.ActiveInKeyWindow), owner: self, userInfo: nil);
                tracking = newTracking;
                self.addTrackingArea(newTracking);
                break;
                
            case NeedsTracking.NoTracking:
                if let realTracking = tracking {
                    self.removeTrackingArea(realTracking);
                    tracking = nil;
                }
            }
        });
    }
}
