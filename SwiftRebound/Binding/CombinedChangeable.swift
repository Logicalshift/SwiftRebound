//
//  CombinedChangeable.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 12/07/2016.
//
//

import Foundation

///
/// Changeable implementation that works by combined many changeable objects into one
///
internal class CombinedChangeable : Changeable {
    /// The chageables that are combined in this one
    private let _combined: [Changeable];
    
    init(changeables: [Changeable]) {
        var flatChangeables = [Changeable]();
        
        // Flatten out the list so that we don't create nested combined changeables
        for changeable in changeables {
            let alsoCombined = changeable as? CombinedChangeable;
            if let alsoCombined = alsoCombined {
                flatChangeables.appendContentsOf(alsoCombined._combined);
            }
        }
        
        _combined = flatChangeables;
    }

    ///
    /// Calls a function any time this value is marked as changed
    ///
    func whenChanged(target: Notifiable) -> Lifetime {
        var lifetimes = [Lifetime]();
        
        // Combine the changeables and generate a lifetime for each one
        for changeable in _combined {
            let lifetime = changeable.whenChanged(target);
            lifetimes.append(lifetime);
        }
        
        // Result is a combined lifetime
        return CombinedLifetime(lifetimes: lifetimes);
    }
}
