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
    
    /// Whether or not a draw or a layout is pending for this view
    fileprivate var (_layoutPending, _drawPending) = (false, false);
    
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
                
                _layoutSubviewsTrigger  = trigger;
                _layoutSubviewsLifetime = lifetime;
                
                return trigger;
            }
        }
    }

    override open func draw(_ rect: CGRect) {
        let trigger = getDrawTrigger();
        
        _queue.sync {
            _drawPending = false;
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
            _layoutPending = false;
            trigger();
        }
    }
    
    ///
    /// Lays out this view. A relayout will be triggered if any of the bindings that are accessed here are changed
    ///
    open func layoutSubviewsReactive() {
        
    }
}
