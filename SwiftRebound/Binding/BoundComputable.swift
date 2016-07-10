//
//  BoundComputable.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

///
/// Default queue used to track changes to computed values
///
/// We need to use a default queue not so much for synchronisation but because it's expensive to call
/// BindingContext.withNewContext when there is no existing context (as it has to create a queue every
/// time if we're not on a binding queue already)
///
private let _defaultComputableQueue = BindingContext.createQueueWithNewContext();

///
/// Represents a bound item whose value is computed by a function
///
/// If the function resolves other bindable methods, then those will be automatically added as dependencies -
/// that is, when those values are changed, so is the computable.
///
internal class BoundComputable<TBoundType> : Bound<TBoundType> {
    /// The function to compute
    private let _compute: () -> TBoundType;
    
    /// The queue that is used to perform the computations
    private let _queue = _defaultComputableQueue;
    
    init(compute: () -> TBoundType) {
        _compute = compute;

        super.init();
    }
    
    ///
    /// Recomputes the value of this bound object and returns the result
    ///
    /// Subclasses must override this to describe how a bound value is updated
    ///
    override func computeValue() -> TBoundType {
        var result: TBoundType? = nil;
        
        let compute = _compute;
        dispatch_sync(_queue, {
            BindingContext.withNewContext {
                // TODO: Clear existing dependencies
                
                // Compute the result
                result = compute();
                
                // TODO: Create new dependencies
            }
        });
        
        return result!;
    }
}