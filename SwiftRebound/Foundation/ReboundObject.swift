//
//  ReboundNSObject.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 15/07/2016.
//
//

import Foundation

public extension NSObject {
    
}

private var _liveAsLongAsPtr = 0;

public extension Lifetime {
    ///
    /// Attaches a lifetime to an object (the lifetime will last as long as the object
    ///
    public func liveAsLongAs(object: AnyObject!) {
        // Fetch the lifetime attached to this object
        let lifetimeObject = objc_getAssociatedObject(object, &_liveAsLongAsPtr) as? CombinedLifetime;
        
        if let lifetimeObject = lifetimeObject {
            // Object already has lifetimes associated with it
            lifetimeObject.addLifetime(self);
        } else {
            // Object needs a new lifetime
            let newLifetime = CombinedLifetime(lifetimes: [self]);
            objc_setAssociatedObject(object, &_liveAsLongAsPtr, newLifetime, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN);
        }
    }
}