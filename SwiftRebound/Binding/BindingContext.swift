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
/// Stores the binding context for the current queue
///
private class QueueBindingContext {
    var context: BindingContext;
    
    init(context: BindingContext) {
        self.context = context;
    }
}

///
/// The binding context is used to keep track of what bindings are being accessed
///
public class BindingContext {
    ///
    /// Call BindingContext.current to get the binding context for the current queue
    ///
    private init() {
    }
    
    private static var currentStorage: QueueBindingContext? {
        @inline(__always)
        get {
            // Get the context pointer from the queue
            let unmanagedContext = dispatch_get_specific(_contextSpecificName);
            if unmanagedContext == nil {
                return nil;
            }
            
            // Convert from the unmanaged value
            return Unmanaged<QueueBindingContext>.fromOpaque(COpaquePointer(unmanagedContext)).takeUnretainedValue();
        }
    }
    
    ///
    /// Retrieves the binding context for the current queue (or nil if there isn't one)
    ///
    public static var current: BindingContext? {
        get {
            return currentStorage?.context;
        }
    }
    
    ///
    /// Creates a new dispatch queue with a new binding context
    ///
    public static func createQueueWithNewContext() -> dispatch_queue_t {
        // Generate a new context
        let newContext  = BindingContext();
        
        // Create a queue to use the context in
        let queue       = dispatch_queue_create("io.logicalshift.binding", nil);
        let storage     = QueueBindingContext(context: newContext);
        let retained    = Unmanaged<QueueBindingContext>.passRetained(storage).toOpaque();
        
        dispatch_queue_set_specific(queue, _contextSpecificName, UnsafeMutablePointer<Void>(retained), { context in
            // Release the context
            Unmanaged<QueueBindingContext>.fromOpaque(COpaquePointer(context)).release();
        });
        
        return queue;
    }
    
    ///
    /// Creates a new binding context (which can be retrieved with current) and performs the specified action with
    /// it in effect
    ///
    public static func withNewContext(action: () -> ()) {
        if let existingStorage = BindingContext.currentStorage {
            // Generate a new context
            let oldContext  = existingStorage.context;
            let newContext  = BindingContext();
            
            // If there's an existing context, append the new context to it and perform the action rather than creating a whole new context
            // Creating new contexts is expensive
            existingStorage.context = newContext;
            action();
            existingStorage.context = oldContext;
        } else {
            // Create a queue to use the context in
            let queue = BindingContext.createQueueWithNewContext();
            
            // Perform the action with this context in effect
            dispatch_sync(queue, {
                action();
            });
        }
    }
    
    ///
    /// Adds a new dependency to the current context (the current context item will be marked as changed)
    ///
    public func addDependency<TBoundType>(dependentOn: Bound<TBoundType>) {
        
    }
};
