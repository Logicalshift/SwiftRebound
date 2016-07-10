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
    init(value: TBoundType) {
        super.init();
        
        _currentValue = value;
    }
    
    override func bindNewValue(newValue: TBoundType) -> TBoundType {
        return newValue;
    }
    
    override func markAsChanged() {
        // These aren't computed, so we can't mark them as changed. We should notify the observers however.
        notifyChange(value);
    }
    
    override func computeValue() -> TBoundType {
        // It should be impossible to reach this point
        // The value is set from outside, so there's nothing to compute
        fatalError("Simple bound values are not computed");
    }
}
