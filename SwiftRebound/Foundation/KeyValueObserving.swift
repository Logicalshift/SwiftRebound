//
//  KeyValueObserving.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 15/07/2016.
//
//

import Foundation

private class ObserverBindings : NSObject {
    private var _attachedBindings = [String: MutableBound<AnyObject?>]();

    /// Callback when an observed binding changes
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        // Keypath must exist
        if let keyPath = keyPath {
            // Must be observing the keypath
            if let binding = _attachedBindings[keyPath] {
                // Change must exist
                if let change = change {
                    // Change must have a new value
                    if let newValue = change[NSKeyValueChangeNewKey] {
                        binding.value = newValue;
                    }
                }
            }
        }
    }
}

/// Key used to get/set the associated bindings object (which actually performs the update)
private var _observerBindingsKey = 0;

public extension NSObject {
    ///
    /// Creates a binding that is updated when the specified key path is changed
    ///
    public func bindKeyPath(keyPath: String) -> Bound<AnyObject?> {
        // Fetch the bindings attached to this object
        let lastBindings = objc_getAssociatedObject(self, &_observerBindingsKey) as? ObserverBindings;
        var attachedBindings: ObserverBindings;
        
        if let lastBindings = lastBindings {
            attachedBindings = lastBindings;
        } else {
            attachedBindings = ObserverBindings();
            objc_setAssociatedObject(self, &_observerBindingsKey, attachedBindings, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN);
        }
        
        // Try to fetch the existing binding
        if let existingBinding = attachedBindings._attachedBindings[keyPath] {
            // Use the existing binding
            return existingBinding;
        } else {
            // Create binding, and observe it
            // TODO: make it so we don't read the value or attach the observer until the binding is first resolved
            let initialValue    = self.valueForKey(keyPath);
            let newBinding      = Binding.create(initialValue);
            
            attachedBindings._attachedBindings[keyPath] = newBinding;
            self.addObserver(attachedBindings, forKeyPath: keyPath, options: NSKeyValueObservingOptions.New, context: nil);
            
            return newBinding;
        }
    }
}
