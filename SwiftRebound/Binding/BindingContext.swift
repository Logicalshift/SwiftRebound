//
//  BindingContext.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

///
/// Key used to retrieve the binding context on the current queue
///
private let _contextSpecificName = DispatchSpecificKey<QueueBindingContext>();

///
/// Semaphore used to decide which context queue to use
///
private let _queueSemaphore = DispatchSemaphore(value: 1);

///
/// Semaphore that is held as long as there are 0 queues available
///
private let _queueWaitSemaphore = DispatchSemaphore(value: 1);

///
/// Queues used to
///
private var _contextQueues = BindingQueuePool.createContextQueues(8);

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
/// Retrieves/returns binding context queues
///
private class BindingQueuePool {
    ///
    /// Creates a set of context queues
    ///
    static func createContextQueues(_ count: Int) -> [DispatchQueue] {
        var result = [DispatchQueue]();
        
        for _ in 0..<count {
            let queue = BindingQueuePool.createQueueWithNewContext();
            result.append(queue);
        }
        
        return result;
    }
    
    ///
    /// Creates a new dispatch queue with a new binding context
    ///
    static func createQueueWithNewContext() -> DispatchQueue {
        // Generate a new context
        let newContext  = BindingContext();
        
        // Create a queue to use the context in
        let queue       = DispatchQueue(label: "io.logicalshift.binding", attributes: []);
        let storage     = QueueBindingContext(context: newContext);
        
        queue.setSpecific(key: _contextSpecificName, value: storage);
        
        return queue;
    }
    
    ///
    /// Retrieves a context queue, or waits for one to become available
    ///
    static func retrieveContextQueue() -> DispatchQueue {
        // Acquire the semaphore
        _queueSemaphore.wait();
        defer { _queueSemaphore.signal(); }
        
        // If there are no queues available, then wait for someone to signal the wait semaphore
        while _contextQueues.count <= 0 {
            // Release the queue semaphore so that queues can be returned
            _queueSemaphore.signal();
            
            // Wait for the wait semaphore to be signaled (indicates a queue was returned to the pool)
            _queueWaitSemaphore.wait();
            _queueWaitSemaphore.signal();
            
            // Re-acquire the queue semaphore so we can check for queues
            _queueSemaphore.wait();
        }
        
        // If we got the semaphore, there is always at least one queue available in the list
        let queue = _contextQueues.popLast()!;
        
        // If we just got the last queue, then acquire the wait semaphore so we can block anything waiting for a queue
        if _contextQueues.count == 0 {
            _queueWaitSemaphore.wait();
        }
        
        // Release the semaphore and return the result
        return queue;
    }
    
    ///
    /// Returns a context queue to the pool
    ///
    static func returnContextQueue(_ queue: DispatchQueue) {
        // Acquire the semaphore
        _queueSemaphore.wait();
        defer { _queueSemaphore.signal(); }
        
        // If this is the first queue back in the pool, then wake any threads waiting for more queues
        if _contextQueues.count == 0 {
            _queueWaitSemaphore.signal();
        }
        
        // Return queue to the pool
        _contextQueues.append(queue);
    }
}

///
/// The binding context is used to keep track of what bindings are being accessed
///
public class BindingContext {
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
    public static var current: BindingContext? {
        get {
            return currentStorage?.context;
        }
    }
    
    ///
    /// Creates a new binding context (which can be retrieved with current) and performs the specified action with
    /// it in effect
    ///
    public static func withNewContext(_ action: () -> ()) {
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
            // Current queue doesn't have any context stored, move on to a queue
            // Could also call createQueueWithNewContext() here, but that is slow
            let queue = BindingQueuePool.retrieveContextQueue();
            defer { BindingQueuePool.returnContextQueue(queue); }
            
            queue.sync(execute: {
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
