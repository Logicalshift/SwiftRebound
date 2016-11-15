//
//  ReactiveView.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 15/11/2016.
//
//

import UIKit

///
/// Base class for views that can trigger redraws and layouts based on bindings
///
open class ReactiveView : UIView {
    /// Trigger for the drawReactive() call
    fileprivate var _drawTrigger: Optional<() -> ()> = nil;
    
    /// Lifetime for the trigger
    fileprivate var _drawLifetime: Lifetime? = nil;
    
    /// Trigger for the layoutReactive() call
    fileprivate var _layoutSubviewsTrigger: Optional<() -> ()> = nil;
    
    /// Lifetime for the trigger
    fileprivate var _layoutSubviewsLifetime: Lifetime? = nil;
    
    /// Queue used for synchronising drawing requests
    fileprivate let _queue = DispatchQueue(label: "io.logicalshift.ReactiveView");

    ///
    /// Retrieves or creates the draw trigger
    ///
    fileprivate func getDrawTrigger() -> () -> () {
        return _queue.sync {
            if let trigger = _drawTrigger {
                return trigger;
            } else {
                let (trigger, lifetime) = Binding.trigger({ [unowned self] in
                    // The caller should run on the queue and set the draw context
                    self.drawReactive();
                }, causeUpdate: { [unowned self] in
                    // Perform the display request async on the queue (we won't queue while we're already drawing)
                    self._queue.async {
                        DispatchQueue.main.sync { self.setNeedsDisplay(); }
                    }
                });
                
                _drawTrigger    = trigger;
                _drawLifetime   = lifetime;
                
                return trigger;
            }
        }
    }
    
    ///
    /// Retrieves or creates the layout trigger
    ///
    fileprivate func getLayoutTrigger() -> () -> () {
        return _queue.sync {
            if let trigger = _layoutSubviewsTrigger {
                return trigger;
            } else {
                let (trigger, lifetime) = Binding.trigger({ [unowned self] in
                    // The caller should run on the queue
                    self.layoutSubviewsReactive();
                    }, causeUpdate: { [unowned self] in
                        // Perform the layout request async on the queue (we won't queue while we're already laying out)
                        self._queue.async {
                            DispatchQueue.main.sync { self.setNeedsLayout() };
                        }
                });
                
                _layoutSubviewsTrigger  = trigger;
                _layoutSubviewsLifetime = lifetime;
                
                return trigger;
            }
        }
    }

    override open func draw(_ rect: CGRect) {
        let trigger = getDrawTrigger();
        
        _queue.sync {
            trigger();
        }
    }
    
    ///
    /// Draws this view. A redraw will be triggered if any of the bindings that are accessed here are changed
    ///
    open func drawReactive() {
        
    }
    
    override open func layoutSubviews() {
        let trigger = getLayoutTrigger();
        
        _queue.sync {
            trigger();
        }
    }
    
    ///
    /// Lays out this view. A relayout will be triggered if any of the bindings that are accessed here are changed
    ///
    open func layoutSubviewsReactive() {
        
    }
}
