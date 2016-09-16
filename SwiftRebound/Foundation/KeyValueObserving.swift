//
//  KeyValueObserving.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 15/07/2016.
//
//

import Foundation

///
/// Collects all the bindings attached to a particular object
///
private class ObserverBindings : NSObject {
    /// The active bindings on this observer
    fileprivate var _attachedBindings = [String: KvoBound]();
    
    /// The target object, or nil if there are no attached bindings
    ///
    /// Cocoa throws an exception if there are any observers attached to an object when it is deinitialised.
    ///
    /// Often, it's unstable in terms of deallocation order of things, so the observers may not get deallocated
    /// first, so this exception is random,
    ///
    /// Therefore, we have to keep the object alive for as long as anything is attached to it.
    /// (Ideally, we'd just consider it as a weak reference as a dead object can't update itself, but there's no
    /// way to control object deallocation order sufficiently. This is annoying as for 'natural' bindings the
    /// behaviour is that if a binding goes away it stops updating)
    fileprivate var _target: NSObject? = nil;
    
    /// How many active attached bindings there are
    fileprivate var _attachCount: Int32 = 0;
    
    ///
    /// Attaches a binding and ensures that the target object is kept in memory
    ///
    func attachBinding(_ target: NSObject) {
        OSAtomicIncrement32(&_attachCount);
        _target = target;
    }
    
    ///
    /// Detaches a binding, allowing the target object to be released if the reference count goes low enough
    ///
    func detachBinding() {
        let newAttachCount = OSAtomicDecrement32(&_attachCount);
        if newAttachCount == 0 {
            _target = nil;
        }
    }

    /// Callback when an observed binding changes
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // Keypath must exist
        if let keyPath = keyPath {
            // Must be observing the keypath
            if let binding = _attachedBindings[keyPath] {
                // This binding has changed
                binding.markAsChanged();
            }
        }
    }
}

///
/// Binding that is used to attach to a KVO path in an object
///
private class KvoBound : Bound<AnyObject?> {
    /// The object we're bound to, or nil if it has gone away
    fileprivate weak var _target: NSObject?;
    
    /// The observer bindings object marks changes as having happened
    fileprivate weak var _observerBindings: ObserverBindings?;
    
    /// The key path that we're bound to
    fileprivate let _keyPath: String;
    
    /// Set to true if we're attached to an observer
    fileprivate var _observing = false;
    
    init(target: NSObject, keyPath: String) {
        _target     = target;
        _keyPath    = keyPath;
    }
    
    override fileprivate func computeValue() -> AnyObject? {
        return _target?.value(forKey: _keyPath) as AnyObject?;
    }
    
    override fileprivate func beginObserving() {
        if let target = _target {
            let bindings = target.getObserverBindings();
            
            // Activate the observer for this key path
            bindings.attachBinding(target);
            target.addObserver(bindings, forKeyPath: _keyPath, options: NSKeyValueObservingOptions.new, context: nil);
            _observing = true;
        }
    }
    
    override fileprivate func doneObserving() {
        if let target = _target {
            let bindings = target.getObserverBindings();
            
            // Deactivate the observer for this key path
            bindings.detachBinding();
            target.removeObserver(bindings, forKeyPath: _keyPath, context: nil);
            _observing = false;
        }
    }
    
    override fileprivate func needsUpdate() -> Bool {
        if !_observing {
            // Not attached to the observer: want to read the key value every time
            return true;
        } else {
            // Attached to an observer: we get notified of changes
            return super.needsUpdate();
        }
    }
}

/// Key used to get/set the associated bindings object (which actually performs the update)
private var _observerBindingsKey = 0;

public extension NSObject {
    ///
    /// Retrieves the observer bindings attached to a NSObject
    ///
    fileprivate func getObserverBindings() -> ObserverBindings {
        // We're a swift object and don't conform to NSObject, so we use an ObserverBindings object which does conform as the target
        // (this also ensures that we only add one observer in total)
        
        // Fetch the bindings attached to the target
        let lastBindings = objc_getAssociatedObject(self, &_observerBindingsKey) as? ObserverBindings;
        var attachedBindings: ObserverBindings;
        
        if let lastBindings = lastBindings {
            attachedBindings = lastBindings;
        } else {
            attachedBindings = ObserverBindings();
            objc_setAssociatedObject(self, &_observerBindingsKey, attachedBindings, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN);
        }
        
        return attachedBindings;
    }

    ///
    /// Creates a binding that is updated when the specified key path is changed
    ///
    /// Note that if anything is observing the binding, then the target object will be kept in memory (this includes computed bindings).
    /// This is done because an exception is thrown if there are any KVO observers attached to an object when it is deinitialised.
    ///
    public func bindKeyPath(_ keyPath: String) -> Bound<AnyObject?> {
        // Fetch the bindings attached to this object
        let attachedBindings = self.getObserverBindings();
        
        // Try to fetch the existing binding
        if let existingBinding = attachedBindings._attachedBindings[keyPath] {
            // Use the existing binding
            return existingBinding;
        } else {
            // Create binding, and observe it
            // TODO: make it so we don't read the value or attach the observer until the binding is first resolved
            let newBinding      = KvoBound(target: self, keyPath: keyPath);
            
            attachedBindings._attachedBindings[keyPath] = newBinding;
            
            return newBinding;
        }
    }
}
