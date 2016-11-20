//
//  Bound.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

///
/// Semaphore used to protect this value against races when being updated on multiple queues
///
/// We don't hold the semaphore for long periods of time and bindings are not supposed to be used for bulk data storage (so
/// very high performance is not a concern) so we share a single semaphore between all bindings instead of having one per
/// binding.
///
fileprivate let _bindingUpdateSemaphore = DispatchSemaphore(value: 1);

///
/// Protocol implemented by objects that can be notified that they need to recalculate themselves
///
public protocol Notifiable : class {
    ///
    /// Mark this item as having been changed
    ///
    /// The next time the value is resolved, it will register as a change and the observers will be called.
    ///
    func markAsChanged();
}

///
/// Protocol implemented by objects that can notify other objects that it has changed
///
public protocol Changeable : class {
    ///
    /// Calls a function any time this value is marked as changed
    ///
    func whenChangedNotify(_ target: Notifiable) -> Lifetime;
}

public extension Changeable {
    ///
    /// Calls a function any time this value is marked as changed
    ///
    public final func whenChanged(_ action: @escaping () -> ()) -> Lifetime {
        return whenChangedNotify(CallbackNotifiable(action: action));
    }
}

///
/// A bound value represents a storage location whose changes can be observed by other objects.
///
/// Bound values are the core of SwiftRebound.
///
open class Bound<TBoundType> : Changeable, Notifiable {
    ///
    /// The value that's current bound to this object, or nil if it has been changed and needs recomputing
    ///
    internal var _currentValue: TBoundType? = nil;
    
    ///
    /// The actions that should be executed when this bound value is changed
    ///
    fileprivate var _actionsOnChanged: [NotificationWrapper] = [];
    
    ///
    /// nil, or a binding that is true if this item is bound to something or false if it is not
    ///
    fileprivate var _isBound: MutableBound<Bool>? = nil;
    
    ///
    /// Must be overridden by subclasses: can't be initialised directly
    ///
    internal init() {
        
    }
    
    ///
    /// Causes any observers to be notified that this object has changed
    ///
    internal final func notifyChange() {
        var needToTidy = false;
        
        // Synchronise access to the actions
        _bindingUpdateSemaphore.wait();
        let actions = _actionsOnChanged;
        _bindingUpdateSemaphore.signal();
        
        // Run any actions that result from this value being updated
        for notificationWrapper in actions {
            if let action = notificationWrapper.target {
                action.markAsChanged();
            } else {
                needToTidy = true;
            }
        }
        
        if needToTidy {
            maybeDoneObserving();
        }
    }
    
    ///
    /// Recomputes and rebinds the value associated with this object (even if it's not marked as being changed)
    ///
    public final func rebind() -> TBoundType {
        // Update the current value
        let currentValue    = computeValue();
        
        _bindingUpdateSemaphore.wait();
        _currentValue       = currentValue;
        _bindingUpdateSemaphore.signal();
        
        return currentValue;
    }
    
    ///
    /// Retrieves the current vaue of this bound value, or nil if it is currently unresolved
    ///
    @inline(__always)
    public final func getCurrentValue() -> TBoundType? {
        _bindingUpdateSemaphore.wait();
        let result = _currentValue;
        _bindingUpdateSemaphore.signal();
        return result;
    }
    
    ///
    /// Ensures that the value associated with this binding has been resolved (if this item has been marked as
    /// changed, forces it to update)
    ///
    @inline(__always)
    public final func resolve() -> TBoundType {
        // Resolving a binding creates a dependency in the current context
        BindingContext.current?.addDependency(self);
        
        if let currentValue = getCurrentValue() {
            return currentValue;
        } else {
            return rebind();
        }
    }
    
    ///
    /// Mark this item as having been changed
    ///
    /// The next time the value is resolved, it will register as a change and the observers will be called.
    ///
    open func markAsChanged() {
        // Notify a change if we're currently resolved (otherwise, assume that the change is still pending and we don't need to notify again)
        _bindingUpdateSemaphore.wait();
        
        if _currentValue != nil {
            _currentValue = nil;
            _bindingUpdateSemaphore.signal();
            
            notifyChange();
        } else {
            _bindingUpdateSemaphore.signal();
        }
    }
    
    ///
    /// Reads the value that this object is bound to
    ///
    open var value: TBoundType {
        @inline(__always)
        get {
            return resolve();
        }
    }
    
    ///
    /// Calls a function any time this value is marked as changed
    ///
    public final func whenChangedNotify(_ target: Notifiable) -> Lifetime {
        // Record this action so we can re-run it when the value changes
        let wrapper = NotificationWrapper(target: target);
        
        _bindingUpdateSemaphore.wait();
        _actionsOnChanged.append(wrapper);
        let isFirstBinding = _actionsOnChanged.count == 1;
        _bindingUpdateSemaphore.signal();
        
        // Perform actions if this is the first binding attached to this object
        if isFirstBinding {
            updateIsBound();
            beginObserving();
        }
        
        // Stop observing the action once the lifetime expires
        return CallbackLifetime(done: {
            wrapper.target = nil;
            self.maybeDoneObserving();
        });
    }

    ///
    /// Calls a function any time this value is changed. The function will be called at least once
    /// with the current value of this bound object
    ///
    public final func observe(_ action: @escaping (TBoundType) -> ()) -> Lifetime {
        var resolving           = false;
        var resolveAgain        = false;
        
        let performObservation  = {
            if !resolving {
                // If we get a side-effect that causes this to need to be fired again, then do so iteratively rather than recursively
                repeat {
                    resolveAgain = false;
                    
                    resolving = true;
                    action(self.resolve());
                    resolving = false;
                } while (resolveAgain);
            } else {
                // Something is currently resolving this observable, cause it to run again
                resolveAgain = true;
            }
        };
        
        // Call and resolve the action whenever this item is changed
        let lifetime = whenChanged(performObservation);

        // As soon as we start observing a value, call the action to generate the initial binding
        performObservation();

        return lifetime;
    }
    
    ///
    /// Recomputes the value of this bound object and returns the result
    ///
    /// Subclasses must override this to describe how a bound value is updated
    ///
    internal func computeValue() -> TBoundType {
        fatalError("computeValue not implemented");
    }
    
    ///
    /// Something has begun observing this object for changes
    ///
    open func beginObserving() {
        // Subclasses may override (eg if they want to add an observer)
    }
    
    ///
    /// All observers have finished their lifetime (called eagerly; normally observers are removed lazily)
    ///
    open func doneObserving() {
        // Subclasses may override (eg if they want to add an observer)
    }
    
    ///
    /// Updates the isBound value so it's current
    ///
    fileprivate func updateIsBound() {
        if let isBound = _isBound {
            _bindingUpdateSemaphore.wait();
            let isNowBound = _actionsOnChanged.count > 0;
            _bindingUpdateSemaphore.signal();
            
            // TODO: really need to set the value within the semaphore
            isBound.value = isNowBound;
        }
    }
    
    ///
    /// Check to see if all notifications are finished with and call doneObserving() if they are
    ///
    fileprivate func maybeDoneObserving() {
        // See if all the notifiers are finished with
        var allDone = true;
        
        // Check if we're done
        _bindingUpdateSemaphore.wait();

        for notifier in _actionsOnChanged {
            if notifier.target != nil {
                allDone = false;
                break;
            }
        }
        
        // Clear out eagerly if all notifiers are finished with
        if allDone {
            _actionsOnChanged = [];
        }
        
        _bindingUpdateSemaphore.signal();
        
        // Notify if we're finished
        if allDone {
            updateIsBound();
            doneObserving();
        }
    }
    
    ///
    /// Returns a binding that is set to true while this binding is being observed
    ///
    /// This can be used as an opportunity to detach or attach event handlers that update a particular value, by observing when it
    /// becomes true or false.
    ///
    open var isBound: Bound<Bool> {
        get {
            _bindingUpdateSemaphore.wait();
            
            if let result = _isBound {
                // Use the existing isBound value
                _bindingUpdateSemaphore.signal();
                
                return result;
            } else {
                // Create a new isBound value
                let result = Binding.create(false);
                _isBound = result;
                
                _bindingUpdateSemaphore.signal();
                
                updateIsBound();
                return result;
            }
        }
    }
}
