//
//  MutableBound.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

///
/// A mutable bound object is a variant of the standard bound object where the value can be set as well
/// as retrieved
///
public class MutableBound<TBoundType> : Bound<TBoundType> {
    ///
    /// Gets or sets the value attached to this bound value
    ///
    override open var value: TBoundType {
        @inline(__always)
        get {
            return resolve();
        }
        set (newValue) {
            // Set the current value immediately
            let lastValue   = _currentValue;
            let finalValue  = bindNewValue(newValue);
            _currentValue   = finalValue;
            
            // Tell any observers that the change has occurred
            if let lastValue = lastValue {
                if isChanged(oldValue: lastValue, newValue: finalValue) {
                    notifyChange();
                }
            } else {
                notifyChange();
            }
        }
    }
    
    ///
    /// Performs action associated with setting the value of this object, returning the actual new value that should be used
    ///
    internal func bindNewValue(_ newValue: TBoundType) -> TBoundType {
        return newValue;
    }
    
    ///
    /// Returns true if oldValue is not the same as newValue
    ///
    internal func isChanged(oldValue: TBoundType, newValue: TBoundType) -> Bool {
        // By default, we don't know, so we always return true
        return true;
    }
}
