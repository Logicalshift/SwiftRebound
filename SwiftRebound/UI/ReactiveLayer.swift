//
//  ReactiveLayer.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 03/11/2016.
//
//

#if os(OSX)
    import Cocoa
#else
    import UIKit
#endif

///
/// Layer that provides a way to draw and layout reactively
///
class ReactiveLayer : CALayer {
    /// Trigger for the drawReactive() call
    fileprivate var _drawTrigger: Optional<() -> ()> = nil;
    
    /// Lifetime for the trigger
    fileprivate var _drawLifetime: Lifetime? = nil;
    
    /// Trigger for the layoutReactive() call
    fileprivate var _layoutSublayersTrigger: Optional<() -> ()> = nil;
    
    /// Lifetime for the trigger
    fileprivate var _layoutSublayersLifetime: Lifetime? = nil;
    
    /// Tracks whether or not we're going to redraw
    fileprivate var _isDrawing = false;
    
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
                    // Perform the display request async on the queue (we won't queue while we're already drawing)
                    self._queue.async {
                        RunLoop.main.performSelector(inBackground: #selector(self.setNeedsDisplay), with: self);
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
                    // Perform the layout request async on the queue (we won't queue while we're already laying out)
                    self._queue.async {
                        RunLoop.main.performSelector(inBackground: #selector(self.setNeedsLayout), with: self);
                    }
            });
            
            _layoutSublayersTrigger     = trigger;
            _layoutSublayersLifetime    = lifetime;
            
            return trigger;
        }
    }
    
    override func draw(in ctx: CGContext) {
        let trigger = getDrawTrigger();
        
        _queue.sync {
            self._drawCtx = ctx;
            trigger();
            self._drawCtx = nil;
        }
    }
    
    override func layoutSublayers() {
        let trigger = getLayoutTrigger();
        
        _queue.sync {
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
