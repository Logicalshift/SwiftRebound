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
    private var _attachedBindings = [String: KvoBound]();

    /// Callback when an observed binding changes
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
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
    private weak var _target: NSObject?;
    
    /// The observer bindings object marks changes as having happened
    private weak var _observerBindings: ObserverBindings?;
    
    /// The key path that we're bound to
    private let _keyPath: String;
    
    /// Set to true if we're attached to an observer
    private var _observing = false;
    
    init(target: NSObject, keyPath: String) {
        _target     = target;
        _keyPath    = keyPath;
    }
    
    override private func computeValue() -> AnyObject? {
        return _target?.valueForKey(_keyPath);
    }
    
    override private func beginObserving() {
        if let target = _target {
            let bindings = target.getObserverBindings();
            
            // Activate the observer for this key path
            target.addObserver(bindings, forKeyPath: _keyPath, options: NSKeyValueObservingOptions.New, context: nil);
            _observing = true;
        }
    }
    
    override private func doneObserving() {
        if let target = _target {
            let bindings = target.getObserverBindings();
            
            // Deactivate the observer for this key path
            target.removeObserver(bindings, forKeyPath: _keyPath, context: nil);
            _observing = false;
        }
    }
    
    override private func needsUpdate() -> Bool {
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
    private func getObserverBindings() -> ObserverBindings {
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
    public func bindKeyPath(keyPath: String) -> Bound<AnyObject?> {
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
