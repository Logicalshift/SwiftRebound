//
//  Bound.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

///
/// A bound value represents a storage location whose changes can be observed by other objects.
///
/// Bound values are the core of SwiftRebound.
///
public class Bound<TBoundType> {
    ///
    /// The value that's current bound to this object, or nil if it has been changed and needs recomputing
    ///
    internal var _currentValue: TBoundType? = nil;
    
    ///
    /// The actions that should be executed when this bound value is changed
    ///
    private var _actionsOnChanged: [(Int, () -> ())] = [];
    
    ///
    /// Next ID to assign to an action
    ///
    private var _nextActionId = 0;
    
    ///
    /// Must be overridden by subclasses: can't be initialised directly
    ///
    internal init() {
        
    }
    
    ///
    /// Causes any observers to be notified that this object has changed
    ///
    final func notifyChange() {
        // Run any actions that result from this value being updated
        for (_, action) in _actionsOnChanged {
            action();
        }
    }
    
    ///
    /// Recomputes and rebinds the value associated with this object (even if it's not marked as being changed)
    ///
    final func rebind() -> TBoundType {
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
    final func resolve() -> TBoundType {
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
    func markAsChanged() {
        if _currentValue != nil {
            _currentValue = nil;
            notifyChange();
        }
    }
    
    ///
    /// Reads the value that this object is bound to
    ///
    var value: TBoundType {
        @inline(__always)
        get {
            return resolve();
        }
    }
    
    ///
    /// Calls a function any time this value is marked as changed
    ///
    final func whenChanged(action: () -> ()) -> Lifetime {
        // Record this action so we can re-run it when the value changes
        let thisActionId = _nextActionId;
        _nextActionId += 1;
        _actionsOnChanged.append((thisActionId, action));
        
        // Stop observing the action once the lifetime expires
        return CallbackLifetime(done: {
            let index = self._actionsOnChanged.indexOf({ (id, _) in return id == thisActionId; });
            if let index = index {
                self._actionsOnChanged.removeAtIndex(index);
            }
        });
    }
    
    ///
    /// Calls a function any time this value is changed. The function will be called at least once
    /// with the current value of this bound object
    ///
    final func observe(action: (TBoundType) -> ()) -> Lifetime {
        // As soon as we start observing a value, call the action to generate the initial binding
        action(resolve());
        
        // Call and resolve the action whenever this item is changed
        return whenChanged {
            action(self.resolve());
        }
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
