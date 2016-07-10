//
//  CallbackLifetime.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

///
/// Lifetime that calls a function when it is finished with
///
public class CallbackLifetime : Lifetime {
    /// Called when this object has been finished with (set to nil immediately after calling)
    private var _done: Optional<() -> ()>;
    
    /// True if we should not call done() from deinit
    private var _isKept = false;
    
    init(done: () -> ()) {
        _done = done;
    }
    
    deinit {
        if let done = _done {
            if !_isKept  {
                done();
                _done = nil;
            }
        }
    }
    
    ///
    /// Indicates that this object should survive even when this Lifetime object has been deinitialised
    ///
    public func keep() -> Void {
        _isKept = true;
    }
    
    ///
    /// Indicates that this object has been finished with
    ///
    public func done() -> Void {
        if let done = _done {
            done();
            _done = nil;
        }
    }
}
