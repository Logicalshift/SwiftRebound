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
/// Binding context queue to use if the current queue is not already a binding queue
///
/// This is not used for the purposes of serialization but rather because creating new queues is bad for performance.
/// This can have the unexpected consequence that all computed values are computed on the same queue.
///
private let _defaultContextQueue = BindingContext.createQueueWithNewContext();

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
    /// The dependencies that have been created in this context
    ///
    private var _dependencies = [Changeable]();
    
    ///
    /// Dependencies that we expected to see
    ///
    private var _expectedDependencies = [Changeable]();
    
    ///
    /// Number of dependencies that we've seen
    ///
    private var _dependencyCount = 0;
    
    ///
    /// Set to true if addDependencies hasn't seen the expected dependencies in the right order
    ///
    private var _dependenciesDiffer = false;
    
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
            // Current queue doesn't have any context stored, move on to the default queue
            // Could also call createQueueWithNewContext() here, but that is slow
            dispatch_sync(_defaultContextQueue, {
                let existingStorage = BindingContext.currentStorage!;
                
                // Generate a new context
                let oldContext  = existingStorage.context;
                let newContext  = BindingContext();
                
                // If there's an existing context, append the new context to it and perform the action rather than creating a whole new context
                // Creating new contexts is expensive
                existingStorage.context = newContext;
                action();
                existingStorage.context = oldContext;
            });
        }
    }
    
    ///
    /// Sets the set of expected dependencies for this item
    ///
    public final func setExpectedDependencies(dependencies: [Changeable]) {
        _expectedDependencies = dependencies;
    }
    
    ///
    /// Adds a new dependency to the current context (the current context item will be marked as changed)
    ///
    @inline(__always)
    public final func addDependency(dependentOn: Changeable) {
        if _dependencyCount >= _expectedDependencies.count || _expectedDependencies[_dependencyCount] !== dependentOn {
            _dependenciesDiffer = true;
        }
        _dependencyCount += 1;
        
        _dependencies.append(dependentOn);
    }
    
    ///
    /// The changeable objects that have been added as dependencies for this context
    ///
    public final var dependencies: [Changeable] {
        @inline(__always)
        get {
            return _dependencies;
        }
    }
    
    ///
    /// True if the expected dependencies and the actual dependencies differ
    ///
    public final var dependenciesDiffer: Bool {
        get {
            return true;
            // return _dependenciesDiffer || _dependencyCount != _expectedDependencies.count;
        }
    }
};
