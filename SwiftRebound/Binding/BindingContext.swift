//
//  BindingContext.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

private let _contextSpecificNameString  = "io.logicalshift.SwiftRebound.BindingContext";
private let _contextSpecificName        = DispatchSpecificKey<QueueBindingContext>();

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
open class BindingContext {
    ///
    /// The dependencies that have been created in this context
    ///
    fileprivate var _dependencies = CombinedChangeable();
    
    ///
    /// Dependencies that we expected to see
    ///
    fileprivate var _expectedDependencies: CombinedChangeable?;
    
    ///
    /// Call BindingContext.current to get the binding context for the current queue
    ///
    fileprivate init() {
    }
    
    fileprivate static var currentStorage: QueueBindingContext? {
        @inline(__always)
        get {
            // Get the context pointer from the queue
            return DispatchQueue.getSpecific(key: _contextSpecificName);
        }
    }
    
    ///
    /// Retrieves the binding context for the current queue (or nil if there isn't one)
    ///
    open static var current: BindingContext? {
        get {
            return currentStorage?.context;
        }
    }
    
    ///
    /// Creates a new dispatch queue with a new binding context
    ///
    open static func createQueueWithNewContext() -> DispatchQueue {
        // Generate a new context
        let newContext  = BindingContext();
        
        // Create a queue to use the context in
        let queue       = DispatchQueue(label: "io.logicalshift.binding", attributes: []);
        let storage     = QueueBindingContext(context: newContext);
        
        queue.setSpecific(key: _contextSpecificName, value: storage);
        
        return queue;
    }
    
    ///
    /// Creates a new binding context (which can be retrieved with current) and performs the specified action with
    /// it in effect
    ///
    open static func withNewContext(_ action: () -> ()) {
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
            _defaultContextQueue.sync(execute: {
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
    public final func setExpectedDependencies(_ dependencies: CombinedChangeable) {
        _expectedDependencies = dependencies;
    }
    
    ///
    /// Adds a new dependency to the current context (the current context item will be marked as changed)
    ///
    public final func addDependency(_ dependentOn: Changeable) {
        _dependencies.addChangeable(dependentOn);
    }
    
    ///
    /// The changeable objects that have been added as dependencies for this context
    ///
    public final var dependencies: CombinedChangeable {
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
            if let expectedDependencies = _expectedDependencies {
                return !expectedDependencies.isSameAs(_dependencies);
            } else {
                return true;
            }
        }
    }
    
    ///
    /// Begins tracking a new set of dependencies
    ///
    public final func resetDependencies() {
        _dependencies = CombinedChangeable();
    }
};
