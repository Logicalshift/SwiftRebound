//
//  CompositeLifetime.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 12/07/2016.
//
//

import Foundation

///
/// Lifetime object that represents the combination of many lifetimes into one
///
public class CombinedLifetime : Lifetime {
    private var _combined: [Lifetime];
    
    public init(lifetimes: [Lifetime]) {
        var flatLifetimes = [Lifetime]();
        
        // Don't nest composite lifetimes: flatten them out into a single array
        for lifetime in lifetimes {
            let alsoComposite = lifetime as? CombinedLifetime;
            if let alsoComposite = alsoComposite {
                flatLifetimes.appendContentsOf(alsoComposite._combined);
            } else {
                flatLifetimes.append(lifetime);
            }
        }
        
        _combined = flatLifetimes;
    }

    ///
    /// Indicates that this object should survive even when this Lifetime object has been deinitialised
    ///
    public func forever() -> Void {
        for lifetime in _combined {
            lifetime.forever();
        }
    }
    
    ///
    /// Indicates that this object has been finished with
    ///
    public func done() -> Void {
        for lifetime in _combined {
            lifetime.done();
        }
        
        _combined = [];
    }
}

extension Lifetime {
    ///
    /// Creates a new lifetime that binds many lifetimes into a single one
    ///
    func liveAsLongAs(lifetimes: Lifetime...) -> Lifetime {
        var compose: [Lifetime] = [self];
        compose.appendContentsOf(lifetimes);
        return CombinedLifetime(lifetimes: compose);
    }
}
