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
internal class BoundComputable<TBoundType> : Bound<TBoundType> {
    /// The function to compute
    private let _compute: () -> TBoundType;
    
    /// Dependencies created the last time this value was computed
    private var _dependencies: [(Changeable, Lifetime)] = [];
    
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
        var newDependencies: [(Changeable, Lifetime)] = [];
        
        // Input for the computation
        let compute         = _compute;
        let oldDependencies = _dependencies;
        let invalidate      = { self.markAsChanged(); }

        BindingContext.withNewContext {
            let currentContext = BindingContext.current!;
            
            // Mark the expected dependencies
            currentContext.setExpectedDependencies(oldDependencies.map { (dep, _) in return dep });
            
            // Compute the result
            result = compute();
            
            if currentContext.dependenciesDiffer {
                // Clear existing dependencies
                for (_, lifetime) in oldDependencies {
                    lifetime.done();
                }

                // Create new dependencies
                for newDependency in BindingContext.current!.dependencies {
                    newDependencies.append((newDependency, newDependency.whenChanged(invalidate)));
                }
            } else {
                newDependencies = oldDependencies;
            }
        }
        
        _dependencies = newDependencies;
        return result!;
    }
}