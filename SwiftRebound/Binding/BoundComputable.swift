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
    
    /// Dependencies created the last time this value was computed
    private var _dependencies: [Lifetime] = [];
    
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
        // Results of the computation
        var result: TBoundType?         = nil;
        var newDependencies: [Lifetime] = [];
        
        // Input for the computation
        let compute         = _compute;
        let oldDependencies = _dependencies;
        let invalidate      = { self.markAsChanged(); }

        BindingContext.withNewContext {
            // Clear existing dependencies
            // TODO: dependencies are often the same before and after a computation, so this would be faster if we didn't clear in the case that they are the same
            for dependency in oldDependencies {
                dependency.done();
            }
            
            // Compute the result
            result = compute();
            
            // Create new dependencies
            for newDependency in BindingContext.current!.dependencies {
                newDependencies.append(newDependency.whenChanged(invalidate));
            }
        }
        
        _dependencies = newDependencies;
        return result!;
    }
}