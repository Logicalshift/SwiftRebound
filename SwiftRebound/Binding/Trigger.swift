//
//  Trigger.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 12/07/2016.
//
//

import Foundation

///
/// A trigger is a function whose operation is monitored for bound variables
///
internal class Trigger : Changeable, Notifiable {
    /// The action that this trigger monitors
    let action: () -> ();
    
    /// The dependencies for the last time the action was run
    private var _dependencies: CombinedChangeable?;

    /// The actions that should be executed when this trigger value is changed
    private var _actionsOnChanged: [NotificationWrapper] = [];
    
    /// Lifetime of the dependency change monitor
    private var _dependencyLifetime: Lifetime?;

    init(action: () -> ()) {
        self.action = action;
    }
    
    ///
    /// Runs the action associated with this trigger
    ///
    func performAction() {
        BindingContext.withNewContext {
            let currentContext  = BindingContext.current!;
            let oldDependencies = self._dependencies;
            
            if let oldDependencies = oldDependencies {
                currentContext.setExpectedDependencies(oldDependencies);
            }
            
            // Run the action in the context
            self.action();
            
            // Rebind the dependencies if they've changed
            if currentContext.dependenciesDiffer {
                self._dependencyLifetime?.done();
                
                let newDependencies = currentContext.dependencies;
                self._dependencies  = newDependencies;
                newDependencies.whenChanged(WeakNotifiable(target: self));
            }
        }
    }

    ///
    /// Calls a function any time this value is marked as changed
    ///
    func whenChanged(target: Notifiable) -> Lifetime {
        // Record this action so we can re-run it when the value changes
        let wrapper = NotificationWrapper(target: target);
        _actionsOnChanged.append(wrapper);
        
        // Stop observing the action once the lifetime expires
        return CallbackLifetime(done: {
            wrapper.target = nil;
        });
    }

    ///
    /// Mark this item as having been changed
    ///
    /// The next time the value is resolved, it will register as a change and the observers will be called.
    ///
    func markAsChanged() {
        var needToTidy = false;
        
        // Run any actions that result from this value being updated
        for notificationWrapper in _actionsOnChanged {
            if let action = notificationWrapper.target {
                action.markAsChanged();
            } else {
                needToTidy = true;
            }
        }
        
        if needToTidy {
            _actionsOnChanged = _actionsOnChanged.filter { notificationWrapper in
                return notificationWrapper.target != nil
            };
        }
    }
}
