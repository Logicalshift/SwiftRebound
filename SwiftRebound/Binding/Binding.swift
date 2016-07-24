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
    public static func create<TBoundType>(value: TBoundType) -> MutableBound<TBoundType> {
        return BoundValue(value: value);
    }
    
    ///
    /// Creates a simple binding to a value of a particular type
    ///
    static func create<TBoundType : Equatable>(value: TBoundType) -> MutableBound<TBoundType> {
        return BoundEquatable(value: value);
    }

    ///
    /// Creates a simple binding to a value of a particular type
    ///
    static func create<TBoundType : AnyObject>(value: TBoundType) -> MutableBound<TBoundType> {
        return BoundReference(value: value);
    }
    
    static func create<TBoundType>(value: [TBoundType]) -> ArrayBound<TBoundType> {
        return ArrayBound(value: value);
    }

    ///
    /// Creates a computed binding
    ///
    /// Computed bindings can access other bindings and will be automatically invalidated when those
    /// bindings change.
    ///
    public static func computed<TBoundType>(compute: () -> TBoundType) -> Bound<TBoundType> {
        return BoundComputable(compute: compute);
    }
    
    ///
    /// Creates a triggered action
    ///
    /// This is something like a drawing function where it can be triggered to update by calling `setNeedsDisplay()`.
    ///
    public static func trigger(action: () -> (), causeUpdate: () -> ()) -> (() -> (), Lifetime) {
        let trigger     = Trigger(action: action);
        let lifetime    = trigger.whenChanged(causeUpdate).liveAsLongAs(trigger);
        
        return (trigger.performAction, lifetime);
    }
};
