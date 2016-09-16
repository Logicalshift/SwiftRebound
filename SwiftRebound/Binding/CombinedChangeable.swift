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
public final class CombinedChangeable : Changeable {
    /// The chageables that are combined in this one
    fileprivate var _combined: [Changeable];
    
    public init() {
        _combined = [];
    }
    
    public init(changeables: [Changeable]) {
        var flatChangeables = [Changeable]();
        
        // Flatten out the list so that we don't create nested combined changeables
        for changeable in changeables {
            let alsoCombined = changeable as? CombinedChangeable;
            if let alsoCombined = alsoCombined {
                flatChangeables.append(contentsOf: alsoCombined._combined);
            }
        }
        
        _combined = flatChangeables;
    }

    ///
    /// Calls a function any time this value is marked as changed
    ///
    public func whenChangedNotify(_ target: Notifiable) -> Lifetime {
        var lifetimes = [Lifetime]();
        
        // Combine the changeables and generate a lifetime for each one
        for changeable in _combined {
            let lifetime = changeable.whenChangedNotify(target);
            lifetimes.append(lifetime);
        }
        
        // Result is a combined lifetime
        return CombinedLifetime(lifetimes: lifetimes);
    }
    
    ///
    /// Adds a new changeable to the changeable items being managed by this object
    ///
    public func addChangeable(_ newChangeable: Changeable) {
        _combined.append(newChangeable);
    }
    
    ///
    /// Finds if this represents the same changeable as the specified combined changeable
    ///
    public func isSameAs(_ compareTo: CombinedChangeable) -> Bool {
        // Lengths must be the same
        if _combined.count != compareTo._combined.count {
            return false;
        }
        
        // Changeables must be the same
        for index in 0..<_combined.count {
            if _combined[index] !== compareTo._combined[index] {
                return false;
            }
        }
        
        return true;
    }
}
