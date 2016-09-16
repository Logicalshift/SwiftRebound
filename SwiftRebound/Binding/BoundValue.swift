//
//  BoundValue.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

///
/// Represents a value that is bound to a simple value that can be updated from outside
///
internal class BoundValue<TBoundType> : MutableBound<TBoundType> {
    required internal init(value: TBoundType) {
        super.init();
        
        _currentValue = value;
    }
    
    override func bindNewValue(_ newValue: TBoundType) -> TBoundType {
        return newValue;
    }
    
    override func markAsChanged() {
        // These aren't computed, so we can't mark them as changed. We should notify the observers however.
        
        // notifyChange can occur at any point after markAsChanged() is called, but must occur before a following
        // resolve() call completes. Here we notify early so we don't need to remember the state for the next
        // resolve call.
        notifyChange();
    }
    
    override func computeValue() -> TBoundType {
        // It should be impossible to reach this point
        // The value is set from outside, so there's nothing to compute
        fatalError("Simple bound values are not computed");
    }
}

internal final class BoundReference<TBoundType : AnyObject> : BoundValue<TBoundType> {
    required internal init(value: TBoundType) {
        super.init(value: value);
    }
        
    internal override func isChanged(oldValue: TBoundType, newValue: TBoundType) -> Bool {
        return oldValue !== newValue;
    }
}

internal final class BoundEquatable<TBoundType : Equatable> : BoundValue<TBoundType> {
    required internal init(value: TBoundType) {
        super.init(value: value);
    }

    internal override func isChanged(oldValue: TBoundType, newValue: TBoundType) -> Bool {
        return oldValue != newValue;
    }
}
