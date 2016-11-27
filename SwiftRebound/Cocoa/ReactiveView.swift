//
//  ReactiveView.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 15/07/2016.
//
//

import Cocoa

open class ReactiveView : NSView {
    /// Trigger for the drawReactive() call
    fileprivate var _drawTrigger: Optional<() -> ()> = nil;
    
    /// Lifetime of the drawReactive() call
    fileprivate var _drawLifetime: Lifetime? = nil;
    
    /// Lifetime of the observer that updates the tracking rectangle
    fileprivate var _trackingObserverLifetime: Lifetime?;
    
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
    
    fileprivate var _isDrawing = false;
    
    override open func draw(_ dirtyRect: NSRect) {
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
                    RunLoop.current.perform(#selector(ReactiveView.triggerRedraw), target: self, argument: nil, order: 0, modes: [RunLoopMode.defaultRunLoopMode]);
                }
            });
            
            _drawTrigger    = trigger;
            _drawLifetime   = lifetime;
            
            trigger();
        }
        
        _isDrawing = false;
    }
    
    open func triggerRedraw() {
        self.setNeedsDisplay(self.bounds);
    }
    
    ///
    /// Should be overridden by subclasses; draws this view
    ///
    /// Any SwiftRebound values used here will be monitored and an update will be triggered if they change
    ///
    open func drawReactive() {
        // Implement in subclasses
    }
    
    /// The position of the mouse over this view
    open var mousePosition: Bound<NSPoint> { get { return _mousePosition; } }
    fileprivate let _mousePosition = Binding.create(NSPoint(x: 0, y: 0));
    
    /// True if the mouse is over this view
    open var mouseOver: Bound<Bool> { get { return _mouseOver; } }
    fileprivate let _mouseOver = Binding.create(false);
    
    /// The pressure used by the stylus over this view
    open var pressure: Bound<Float> { get { return _pressure; } }
    fileprivate let _pressure = Binding.create(Float(0.0));
    
    /// True if any mouse button is down
    open var anyMouseDown: Bound<Bool> { get { return _anyMouseDown; } }
    fileprivate let _anyMouseDown = Binding.create(false);
    
    /// True if the left mouse button has been clicked over this view
    open var leftMouseDown: Bound<Bool> { get { return _leftMouseDown; } }
    fileprivate let _leftMouseDown = Binding.create(false);
    
    /// True if the right mouse button has been clicked over this view
    open var rightMouseDown: Bound<Bool> { get { return _rightMouseDown; } }
    fileprivate let _rightMouseDown = Binding.create(false);

    /// The bounds for this view (bound object)
    open var reactiveBounds: Bound<NSRect> { get { return _reactiveBounds; } }
    fileprivate let _reactiveBounds = Binding.create(NSRect());
    
    /// The frame for this view (bound object)
    open var reactiveFrame: Bound<NSRect> { get { return _reactiveFrame; } }
    fileprivate let _reactiveFrame = Binding.create(NSRect());
    
    ///
    /// Updates mouse properties for this view from an event
    ///
    fileprivate func updateMouseProperties(_ event: NSEvent) {
        // Read from the event
        let newMousePos = convert(event.locationInWindow, from: nil);
        var leftDown    = self.leftMouseDown.value;
        var rightDown   = self.rightMouseDown.value;
        let pressure    = event.pressure;
        
        switch (event.type) {
        case .leftMouseDown:    leftDown = true; break;
        case .leftMouseUp:      leftDown = false; break;
        case .rightMouseDown:   rightDown = true; break;
        case .rightMouseUp:     rightDown = false; break;
        default:                break;
        }
        
        let anyDown = leftDown || rightDown;
        
        // Update the properties
        if newMousePos != self.mousePosition.value {
            self._mousePosition.value = newMousePos;
        }
        
        if leftDown != self.leftMouseDown.value {
            self._leftMouseDown.value = leftDown;
        }
        
        if rightDown != self.rightMouseDown.value {
            self._rightMouseDown.value = rightDown;
        }
        
        if anyDown != self.anyMouseDown.value {
            self._anyMouseDown.value = anyDown;
        }
        
        if pressure != self.pressure.value {
            self._pressure.value = pressure;
        }
    }
    
    override open func mouseDown(with theEvent: NSEvent)           { updateMouseProperties(theEvent); }
    override open func mouseUp(with theEvent: NSEvent)             { updateMouseProperties(theEvent); }
    override open func mouseDragged(with theEvent: NSEvent)        { updateMouseProperties(theEvent); }
    override open func rightMouseDown(with theEvent: NSEvent)      { updateMouseProperties(theEvent); }
    override open func rightMouseUp(with theEvent: NSEvent)        { updateMouseProperties(theEvent); }
    override open func rightMouseDragged(with theEvent: NSEvent)   { updateMouseProperties(theEvent); }
    override open func otherMouseDown(with theEvent: NSEvent)      { updateMouseProperties(theEvent); }
    override open func otherMouseUp(with theEvent: NSEvent)        { updateMouseProperties(theEvent); }
    override open func otherMouseDragged(with theEvent: NSEvent)   { updateMouseProperties(theEvent); }
    override open func mouseMoved(with theEvent: NSEvent)          { updateMouseProperties(theEvent); }
    
    override open func mouseEntered(with theEvent: NSEvent) {
        if !self._mouseOver.value {
            self._mouseOver.value        = true;
            self._mousePosition.value    = self.convert(theEvent.locationInWindow, from: nil);
        }
    }
    override open func mouseExited(with theEvent: NSEvent) {
        if _mouseOver.value { _mouseOver.value = false; }
    }
    
    ///
    /// Updates the frame/bounds values, if they're different
    ///
    fileprivate func updateFrameAndBounds() {
        let newBounds   = bounds;
        let newFrame    = frame;
        
        if _reactiveBounds.value != newBounds {
            _reactiveBounds.value = newBounds;
        }
        
        if _reactiveFrame.value != newFrame {
            _reactiveFrame.value = newFrame;
        }
    }
    
    override open func setBoundsOrigin(_ newOrigin: NSPoint) {
        super.setBoundsOrigin(newOrigin);
        
        updateFrameAndBounds();
    }
    
    override open func setBoundsSize(_ newSize: NSSize) {
        super.setBoundsSize(newSize);
        
        updateFrameAndBounds();
    }
    
    override open func setFrameOrigin(_ newOrigin: NSPoint) {
        super.setFrameOrigin(newOrigin);
        
        updateFrameAndBounds();
    }
    
    override open func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize);
        
        updateFrameAndBounds();
    }
    
    ///
    /// Sets up the observers for this view
    ///
    fileprivate func setupObservers() {
        // Computed that works out whether or not we need a tracking rectangle
        enum NeedsTracking {
            case keepTracking
            case needTracking
            case trackEnterExitOnly
            case noTracking
        }
        
        let needsTracking = Binding.computed({ [unowned self] () -> NeedsTracking in
            // If something is observing the mouse position...
            if self.mousePosition.isBound.value {
                if !self.anyMouseDown.value {
                    // Need to track the mouse if the mouse isn't clicked (we get positions anyway if it is down)
                    return NeedsTracking.needTracking;
                } else if !self.mouseOver.isBound.value {
                    // Leave the tracking as what it was if the mouse is clicked
                    return NeedsTracking.keepTracking;
                }
            }
 
            // If something is observing whether or not we're over the window, then track only enter/exits
            if self.mouseOver.isBound.value {
                return NeedsTracking.trackEnterExitOnly;
            }
            
            // Don't need tracking otherwise
            return NeedsTracking.noTracking;
        });
        
        // Tracking bounds tracks whether or not we need a tracking rectangle and whether or not it's active
        let trackingBounds = Binding.computed({ [unowned self] () -> (NSRect, NeedsTracking) in
            let boundsRect  = self.reactiveBounds.value;
            return (boundsRect, needsTracking.value);
        });
        
        // Add or remove a tracking rectangle if needsTracking changes or the size of the view changes
        var tracking: NSTrackingArea?;
        
        _trackingObserverLifetime = trackingBounds.observe({ [unowned self] (bounds, needsTracking) in
            switch needsTracking {
            case .keepTracking: break;
                
            case .needTracking:
                if let tracking = tracking { self.removeTrackingArea(tracking); }

                let newTracking = NSTrackingArea(rect: bounds, options: NSTrackingAreaOptions.mouseMoved.union(NSTrackingAreaOptions.mouseEnteredAndExited).union(NSTrackingAreaOptions.activeInKeyWindow), owner: self, userInfo: nil);
                tracking = newTracking;
                self.addTrackingArea(newTracking);
                break;
                
            case .trackEnterExitOnly:
                if let tracking = tracking { self.removeTrackingArea(tracking); }
                
                let newTracking = NSTrackingArea(rect: bounds, options: NSTrackingAreaOptions.mouseEnteredAndExited.union(NSTrackingAreaOptions.activeInKeyWindow), owner: self, userInfo: nil);
                tracking = newTracking;
                self.addTrackingArea(newTracking);
                break;
                
            case .noTracking:
                if let realTracking = tracking {
                    self.removeTrackingArea(realTracking);
                    tracking = nil;
                }
            }
        });
    }
}
