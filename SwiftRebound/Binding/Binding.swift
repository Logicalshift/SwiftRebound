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
    fileprivate init() {
        // This class has only static methods: you can't create an instance
    }
    
    ///
    /// Creates a simple binding to a value of a particular type
    ///
    public static func create<TBoundType>(_ value: TBoundType) -> MutableBound<TBoundType> {
        return BoundValue(value: value);
    }
    
    ///
    /// Creates a simple binding to a value of a particular type
    ///
    public static func create<TBoundType : Equatable>(_ value: TBoundType) -> MutableBound<TBoundType> {
        return BoundEquatable(value: value);
    }

    ///
    /// Creates a simple binding to a value of a particular type
    ///
    public static func create<TBoundType : AnyObject>(_ value: TBoundType) -> MutableBound<TBoundType> {
        return BoundReference(value: value);
    }
    
    ///
    /// Creates a binding for an array value of a particular type
    ///
    public static func create<TBoundType>(_ value: [TBoundType]) -> ArrayBound<TBoundType> {
        return ArrayBound(value: value);
    }
    
    ///
    /// Creates a binding that can be used as an attachment point for other bindings
    ///
    /// Attachments are bindings that track the value of a different binding
    ///
    public static func attachment<TBoundType>(_ defaultValue: TBoundType) -> AttachmentPoint<TBoundType> {
        let defaultBinding = create(defaultValue);
        
        return AttachmentPoint(defaultAttachment: defaultBinding);
    }

    ///
    /// Creates a computed binding
    ///
    /// Computed bindings can access other bindings and will be automatically invalidated when those
    /// bindings change.
    ///
    public static func computed<TBoundType>(_ compute: @escaping () -> TBoundType) -> Bound<TBoundType> {
        return BoundComputable(compute: compute);
    }
    
    ///
    /// Creates a triggered action
    ///
    /// This is something like a drawing function where it can be triggered to update by calling `setNeedsDisplay()`.
    ///
    public static func trigger(_ action: @escaping () -> (), causeUpdate: @escaping () -> ()) -> (() -> (), Lifetime) {
        let trigger     = Trigger(action: action);
        let lifetime    = trigger.whenChanged(causeUpdate).liveAsLongAs(trigger);
        
        return (trigger.performAction, lifetime);
    }
};
