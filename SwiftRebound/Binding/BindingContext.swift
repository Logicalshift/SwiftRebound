//
//  BindingContext.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

private let _contextSpecificNameString  = "io.logicalshift.SwiftRebound.BindingContext";
private let _contextSpecificName        = UnsafePointer<Void>((_contextSpecificNameString as NSString).UTF8String);

///
/// The binding context is used to keep track of what bindings are being accessed
///
public class BindingContext {
    ///
    /// Call BindingContext.current to get the binding context for the current queue
    ///
    private init() {
    }
    
    ///
    /// Retrieves the binding context for the current queue (or nil if there isn't one)
    ///
    public static var current: BindingContext? {
        get {
            // Get the context pointer from the queue
            let unmanagedContext = dispatch_get_specific(_contextSpecificName);
            if unmanagedContext == nil {
                return nil;
            }
            
            // Convert from the unmanaged value
            return Unmanaged<BindingContext>.fromOpaque(COpaquePointer(unmanagedContext)).takeUnretainedValue();
        }
    }
    
    ///
    /// Creates a new binding context (which can be retreived with current) and performs the specified action with
    /// it in effect
    ///
    public static func withNewContext(action: () -> ()) {
        // Generate a new context
        let newContext  = BindingContext();
        
        // Create a queue to use the context in
        let queue       = dispatch_queue_create("io.logicalshift.binding", nil);
        let retained    = Unmanaged<BindingContext>.passRetained(newContext).toOpaque();
        
        dispatch_queue_set_specific(queue, _contextSpecificName, UnsafeMutablePointer<Void>(retained), { context in
            // Release the context
            Unmanaged<BindingContext>.fromOpaque(COpaquePointer(context)).release();
        });
        
        // Perform the action with this context in effect
        dispatch_sync(queue, {
            action();
        });
    }
};
