//
//  BoundComputable.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

///
/// Represents a bound item whose value is computed by a function
///
/// If the function resolves other bindable methods, then those will be automatically added as dependencies -
/// that is, when those values are changed, so is the computable.
///
internal final class BoundComputable<TBoundType> : Bound<TBoundType> {
    /// The function to compute
    fileprivate let _compute: () -> TBoundType;
    
    /// Dependencies created the last time this value was computed
    fileprivate var _dependencies: CombinedChangeable?;
    
    /// Lifetime of the dependencies
    fileprivate var _dependencyLifetime: Lifetime?;
    
    init(compute: @escaping () -> TBoundType) {
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
        var result: TBoundType? = nil;
        
        // Input for the computation
        let compute         = _compute;
        let oldDependencies = _dependencies;

        BindingContext.withNewContext {
            let currentContext = BindingContext.current!;
            
            // Mark the expected dependencies
            if let oldDependencies = oldDependencies {
                currentContext.setExpectedDependencies(oldDependencies);
            }
            
            // Compute the result
            result = compute();
            
            if currentContext.dependenciesDiffer {
                // Clear existing dependencies
                let lastLifetime = self._dependencyLifetime;

                // Create new dependencies
                let newDependencies         = currentContext.dependencies;
                self._dependencies          = newDependencies;
                self._dependencyLifetime    = newDependencies.whenChangedNotify(WeakNotifiable(target: self));
                
                #if DEBUG
                if newDependencies.isEmpty {
                    NSLog("Warning: computed value is bound to nothing (will never trigger an update)");
                }
                #endif

                // Start tracking a new dependency set in case ending the lifetime creates accidental bindings
                currentContext.resetDependencies();

                // Finished with the old dependencies
                lastLifetime?.done();
            }
        }

        return result!;
    }
    
    override func doneObserving() {
        _dependencyLifetime?.done();
        _dependencyLifetime = nil;
        _dependencies       = nil;
        
        markAsChanged();
    }
}
