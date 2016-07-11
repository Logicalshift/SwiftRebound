//
//  Bound.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

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
    func whenChanged(target: Notifiable) -> Lifetime;
}

///
/// Wrapper that can be used to determine whether or not a particular notification target still exists
///
private class NotificationWrapper {
    private var target : Notifiable?;
    
    init(target: Notifiable) {
        self.target = target;
    }
}

///
/// A bound value represents a storage location whose changes can be observed by other objects.
///
/// Bound values are the core of SwiftRebound.
///
public class Bound<TBoundType> : Changeable, Notifiable {
    ///
    /// The value that's current bound to this object, or nil if it has been changed and needs recomputing
    ///
    internal var _currentValue: TBoundType? = nil;
    
    ///
    /// The actions that should be executed when this bound value is changed
    ///
    private var _actionsOnChanged: [NotificationWrapper] = [];
    
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
        
        // Run any actions that result from this value being updated
        for notificationWrapper in _actionsOnChanged {
            if let action = notificationWrapper.target {
                action.markAsChanged();
            } else {
                needToTidy = true;
            }
        }
        
        if needToTidy {
            _actionsOnChanged = _actionsOnChanged.filter { notificationWrapper in
                return notificationWrapper.target != nil
            };
            
            
        }
    }
    
    ///
    /// Recomputes and rebinds the value associated with this object (even if it's not marked as being changed)
    ///
    public final func rebind() -> TBoundType {
        // Update the current value
        let currentValue    = computeValue();
        _currentValue       = currentValue;
        
        return currentValue;
    }
    
    ///
    /// Ensures that the value associated with this binding has been resolved (if this item has been marked as
    /// changed, forces it to update)
    ///
    @inline(__always)
    public final func resolve() -> TBoundType {
        // Resolving a binding creates a dependency in the current context
        BindingContext.current?.addDependency(self);
        
        if let currentValue = _currentValue {
            // If the current value is not dirty (ie, we've got it cached), then use that
            return currentValue;
        } else {
            // If the value is dirty, then compute it before returning it
            return rebind();
        }
    }
    
    ///
    /// Mark this item as having been changed
    ///
    /// The next time the value is resolved, it will register as a change and the observers will be called.
    ///
    public func markAsChanged() {
        if _currentValue != nil {
            _currentValue = nil;
            notifyChange();
        }
    }
    
    ///
    /// Reads the value that this object is bound to
    ///
    public var value: TBoundType {
        @inline(__always)
        get {
            return resolve();
        }
    }
    
    ///
    /// Calls a function any time this value is marked as changed
    ///
    public final func whenChanged(target: Notifiable) -> Lifetime {
        // Record this action so we can re-run it when the value changes
        let wrapper = NotificationWrapper(target: target);
        _actionsOnChanged.append(wrapper);
        
        // Stop observing the action once the lifetime expires
        return CallbackLifetime(done: {
            wrapper.target = nil;
        });
    }

    ///
    /// Calls a function any time this value is marked as changed
    ///
    public final func whenChanged(action: () -> ()) -> Lifetime {
        return whenChanged(CallbackNotifiable(action: action));
    }

    ///
    /// Calls a function any time this value is changed. The function will be called at least once
    /// with the current value of this bound object
    ///
    public final func observe(action: (TBoundType) -> ()) -> Lifetime {
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
}
