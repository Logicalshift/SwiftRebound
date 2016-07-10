//
//  Lifetime.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

///
/// Objects that implement the lifetime protocol are used to manage how long a resource is kept in existence
///
/// Lifetime objects should usually release their resource when they're deallocated or when `done` is called.
/// Optionally, `keep` may be called to indicate that the resource should remain even when the Lifetime is
/// deallocated.
///
/// For example, when `observe` is called on a bound value, the callback usually only lasts as long as the
/// Lifetime that's returned from that call. However, the callback can be made to last as long as the bound
/// value itself by calling keep() and discarding the lifetime.
///
public protocol Lifetime {
    ///
    /// Indicates that this object should survive even when this Lifetime object has been deinitialised
    ///
    func keep() -> Void;
    
    ///
    /// Indicates that this object has been finished with
    ///
    func done() -> Void;
}
