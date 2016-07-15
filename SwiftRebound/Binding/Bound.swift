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

public extension Changeable {
    ///
    /// Calls a function any time this value is marked as changed
    ///
    public final func whenChanged(action: () -> ()) -> Lifetime {
        return whenChanged(CallbackNotifiable(action: action));
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
    /// nil, or a binding that is true if this item is bound to something or false if it is not
    ///
    private var _isBound: MutableBound<Bool>? = nil;
    
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
        
        if !needsUpdate() {
            // If the current value is not dirty (ie, we've got it cached), then use that
            return _currentValue!;
        } else {
            // If the value is dirty, then compute it before returning it
            return rebind();
        }
    }
    
    ///
    /// Returns true if the cached value needs updating
    ///
    public func needsUpdate() -> Bool {
        return _currentValue == nil;
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
        if _actionsOnChanged.count == 0 {
            _isBound?.value = true;
            beginObserving();
        }
        
        // Record this action so we can re-run it when the value changes
        let wrapper = NotificationWrapper(target: target);
        _actionsOnChanged.append(wrapper);
        
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
    
    ///
    /// Something has begun observing this object for changes
    ///
    public func beginObserving() {
        // Subclasses may override (eg if they want to add an observer)
    }
    
    ///
    /// All observers have finished their lifetime (called eagerly; normally observers are removed lazily)
    ///
    public func doneObserving() {
        // Subclasses may override (eg if they want to add an observer)
    }
    
    ///
    /// Check to see if all notifications are finished with and call doneObserving() if they are
    ///
    private func maybeDoneObserving() {
        // See if all the notifiers are finished with
        var allDone = true;
        for notifier in _actionsOnChanged {
            if notifier.target != nil {
                allDone = false;
                break;
            }
        }
        
        // Clear out eagerly if all notifiers are finished with
        if allDone {
            _actionsOnChanged = [];
            _isBound?.value = false;
            doneObserving();
        }
    }
    
    ///
    /// Returns a binding that is set to true while this binding is being observed
    ///
    /// This can be used as an opportunity to detach or attach event handlers that update a particular value, by observing when it
    /// becomes true or false.
    ///
    public var isBound: Bound<Bool> {
        get {
            if let result = _isBound {
                return result;
            } else {
                let result = Binding.create(_actionsOnChanged.count > 0);
                _isBound = result;
                return result;
            }
        }
    }
}
