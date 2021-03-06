//
//  ReactiveLayer.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 03/11/2016.
//
//

#if os(OSX)
    import Cocoa
    
    fileprivate let runLoopModes = [ RunLoopMode.defaultRunLoopMode, RunLoopMode.eventTrackingRunLoopMode ];
#else
    import UIKit
    
    fileprivate let runLoopModes = [ RunLoopMode.defaultRunLoopMode, RunLoopMode.UITrackingRunLoopMode ];
#endif

///
/// Layer that provides a way to draw and layout reactively
///
open class ReactiveLayer : CALayer {
    /// Trigger for the drawReactive() call
    fileprivate var _drawTrigger: Optional<() -> ()> = nil;
    
    /// Lifetime for the trigger
    fileprivate var _drawLifetime: Lifetime? = nil;
    
    /// Trigger for the layoutReactive() call
    fileprivate var _layoutSublayersTrigger: Optional<() -> ()> = nil;
    
    /// Whether or not a draw or a layout is pending for this layer
    fileprivate var (_layoutPending, _drawPending) = (false, false);
    
    /// Lifetime for the trigger
    fileprivate var _layoutSublayersLifetime: Lifetime? = nil;
    
    /// Queue used for synchronising drawing requests
    fileprivate let _queue = DispatchQueue(label: "io.logicalshift.ReactiveLayer");
    
    /// Context used for drawing
    fileprivate var _drawCtx: CGContext?;
    
    ///
    /// Retrieves or creates the draw trigger
    ///
    fileprivate func getDrawTrigger() -> () -> () {
        if let trigger = _drawTrigger {
            return trigger;
        } else {
            let (trigger, lifetime) = Binding.trigger({ [unowned self] in
                // The caller should run on the queue and set the draw context
                self.drawReactive(in: self._drawCtx!);
                }, causeUpdate: { [unowned self] in
                    // Perform the display request on the main queue
                    MainQueue.perform {
                        self._queue.sync {
                            if !self._drawPending {
                                self._drawPending = true;
                                self.setNeedsDisplay();
                            }
                        }
                    }
            });
            
            _drawTrigger    = trigger;
            _drawLifetime   = lifetime;
            
            return trigger;
        }
    }
    
    ///
    /// Retrieves or creates the layout trigger
    ///
    fileprivate func getLayoutTrigger() -> () -> () {
        if let trigger = _layoutSublayersTrigger {
            return trigger;
        } else {
            let (trigger, lifetime) = Binding.trigger({ [unowned self] in
                // The caller should run on the queue
                self.layoutSublayersReactive();
                }, causeUpdate: { [unowned self] in
                    // Perform the layout request on the main queue
                    MainQueue.perform {
                        self._queue.sync {
                            if !self._layoutPending {
                                self._layoutPending = true;
                                self.setNeedsLayout();
                            }
                        }
                    }
            });
            
            _layoutSublayersTrigger     = trigger;
            _layoutSublayersLifetime    = lifetime;
            
            return trigger;
        }
    }
    
    override open func draw(in ctx: CGContext) {
        let trigger = getDrawTrigger();
        
        _queue.sync {
            self._drawPending = false;
            self._drawCtx = ctx;
            trigger();
            self._drawCtx = nil;
        }
    }
    
    override open func layoutSublayers() {
        let trigger = getLayoutTrigger();
        
        _queue.sync {
            self._layoutPending = false;
            trigger();
        }
    }
    
    ///
    /// Should be overridden in subclasses: draws the layer, and triggers a redraw if any of the context items change
    ///
    open func drawReactive(in ctx: CGContext) {
        
    }
    
    ///
    /// Should be overidden in subclasses: lays out the sub layers, and triggers a re-layout if any of the context items change
    ///
    open func layoutSublayersReactive() {
        
    }
}
