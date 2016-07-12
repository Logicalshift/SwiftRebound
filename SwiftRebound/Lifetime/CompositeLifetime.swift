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
internal class CompositeLifetime : Lifetime {
    let lifetimes: [Lifetime];
    
    init(lifetimes: [Lifetime]) {
        var storedLifetimes = [Lifetime]();
        
        // Don't nest composite lifetimes: flatten them out into a single array
        for lifetime in lifetimes {
            let alsoComposite = lifetime as? CompositeLifetime;
            if let alsoComposite = alsoComposite {
                storedLifetimes.appendContentsOf(alsoComposite.lifetimes);
            } else {
                storedLifetimes.append(lifetime);
            }
        }
        
        self.lifetimes = storedLifetimes;
    }

    ///
    /// Indicates that this object should survive even when this Lifetime object has been deinitialised
    ///
    func forever() -> Void {
        for lifetime in lifetimes {
            lifetime.forever();
        }
    }
    
    ///
    /// Indicates that this object has been finished with
    ///
    func done() -> Void {
        for lifetime in lifetimes {
            lifetime.done();
        }
    }
}

extension Lifetime {
    ///
    /// Creates a new lifetime that binds many lifetimes into a single one
    ///
    func liveAsLongAs(lifetimes: Lifetime...) -> Lifetime {
        var compose: [Lifetime] = [self];
        compose.appendContentsOf(lifetimes);
        return CompositeLifetime(lifetimes: compose);
    }
}
