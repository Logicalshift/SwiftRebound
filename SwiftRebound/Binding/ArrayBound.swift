//
//  BoundArray.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 24/07/2016.
//
//

import Foundation

///
/// Represents a replacement in an array
///
public struct ArrayReplacement<TBoundType> {
    /// The range of indexes that have been replaced (start, length)
    let range: Range<Int>;
    
    /// The data that is being replaced
    let replacedData: [TBoundType];
    
    /// The replacement data for the range
    let newData: [TBoundType];
}

///
/// Represents a binding for an array
///
public final class ArrayBound<TBoundType> : MutableBound<[TBoundType]> {
    init(value: [TBoundType]) {
        super.init();
        
        _currentValue = value;
    }
    
    ///
    /// Gets or sets the value attached to this bound value
    ///
    override public var value: [TBoundType] {
        @inline(__always)
        get {
            return resolve();
        }
        set (newValue) {
            // Set the current value immediately
            _currentValue = newValue;
            notifyChange();
        }
    }
    
    public override func bindNewValue(newValue: [TBoundType]) -> [TBoundType] {
        return newValue;
    }
    
    public override func markAsChanged() {
        // These aren't computed, so we can't mark them as changed. We should notify the observers however.
        
        // notifyChange can occur at any point after markAsChanged() is called, but must occur before a following
        // resolve() call completes. Here we notify early so we don't need to remember the state for the next
        // resolve call.
        notifyChange();
    }
    
    public override func computeValue() -> [TBoundType] {
        // It should be impossible to reach this point
        // The value is set from outside, so there's nothing to compute
        fatalError("Bound arrays are not computed");
    }
    
    ///
    /// Returns a binding that maps to the most recent replacement performed on this array
    ///
    public var lastReplacement: Bound<ArrayReplacement<TBoundType>> {
        get {
            if let result = _lastReplacement {
                return result;
            } else {
                let result = Binding.create(ArrayReplacement<TBoundType>(range: 0..<0, replacedData: [], newData: []));
                _lastReplacement = result;
                return result;
            }
        }
    }
    private var _lastReplacement: MutableBound<ArrayReplacement<TBoundType>>? = nil;
    
    ///
    /// Retrieves or replaces a range in this collection
    ///
    public subscript(range: Range<Int>) -> [TBoundType] {
        set(newData) {
            if _currentValue != nil {
                let oldData = Array(_currentValue![range]);
                _currentValue!.replaceRange(range, with: newData);

                notifyChange();
                
                if let lastReplacement = _lastReplacement {
                    lastReplacement.value = ArrayReplacement<TBoundType>(range: range, replacedData: oldData, newData: newData);
                }
            }
        }
        
        get {
            BindingContext.current?.addDependency(self);
            
            if let array = _currentValue {
                let result = Array(array[range]);
                return result;
            } else {
                return [];
            }
        }
    }

    ///
    /// Retrieves or replaces a single item from this collection
    ///
    public subscript(index: Int) -> TBoundType {
        set(newItem) {
            self[index..<index+1] = [newItem];
        }
        get {
            BindingContext.current?.addDependency(self);
            
            return _currentValue![index];
        }
    }
    
    ///
    /// Empties this collection
    ///
    public func removeAll() {
        self[0..<count] = [];
    }
    
    ///
    /// The number of elements in this collection
    ///
    public var count: Int {
        get {
            BindingContext.current?.addDependency(self);
            
            return _currentValue!.count;
        }
    }
    
    ///
    /// First element in the array
    ///
    public var first: TBoundType? {
        get {
            BindingContext.current?.addDependency(self);
            
            return _currentValue!.first;
        }
    }
    
    ///
    /// Last element in the array
    ///
    public var last: TBoundType? {
        get {
            BindingContext.current?.addDependency(self);
            
            return _currentValue!.last;
        }
    }
    
    ///
    /// Returns the index of the first item to match the predicate
    ///
    public func indexOf(predicate: TBoundType -> Bool) -> Int? {
        BindingContext.current?.addDependency(self);
        
        return _currentValue!.indexOf(predicate);
    }
};

extension ArrayBound {
    public func insert(value: TBoundType, at: Int) {
        self[at..<at] = [value];
    }

    public func append(value: TBoundType) {
        let count = self.count;
        self[count..<count] = [value];
    }
}
