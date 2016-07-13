//
//  Binding.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

///
/// The binding class provides methods for creating and managing bound objects
///
public class Binding {
    private init() {
        // This class has only static methods: you can't create an instance
    }
    
    ///
    /// Creates a simple binding to a value of a particular type
    ///
    static func create<TBoundType>(value: TBoundType) -> MutableBound<TBoundType> {
        return BoundValue(value: value);
    }
    
    ///
    /// Creates a computed binding
    ///
    /// Computed bindings can access other bindings and will be automatically invalidated when those
    /// bindings change.
    ///
    static func computed<TBoundType>(compute: () -> TBoundType) -> Bound<TBoundType> {
        return BoundComputable(compute: compute);
    }
    
    ///
    /// Creates a triggered action
    ///
    /// This is something like a drawing function where it can be triggered to update by calling `setNeedsDisplay()`.
    ///
    static func trigger(action: () -> (), causeUpdate: () -> ()) -> (() -> (), Lifetime) {
        let trigger     = Trigger(action: action);
        let lifetime    = trigger.whenChanged(causeUpdate).liveAsLongAs(trigger);
        
        return (trigger.performAction, lifetime);
    }
};
