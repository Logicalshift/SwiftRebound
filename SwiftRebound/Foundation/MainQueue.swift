//
//  MainQueue.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 19/11/2016.
//
//

import Foundation

fileprivate let _mainQueueKey = MainQueue.createKey();

///
/// Contains some methods to help out with performing actions on the main dispatch queue
///
class MainQueue {
    ///
    /// Generates the key we use to tell which queue we're running on
    ///
    fileprivate static func createKey() -> DispatchSpecificKey<String> {
        let newKey = DispatchSpecificKey<String>();
        
        DispatchQueue.main.setSpecific(key: newKey, value: "mainQueue");

        return newKey;
    }
    
    ///
    /// Returns true if we're running on the main dispatch queue
    ///
    fileprivate static func isRunningOnMain() -> Bool {
        let keyValue = DispatchQueue.getSpecific(key: _mainQueueKey);
        if keyValue == nil {
            return false;
        } else {
            return true;
        }
    }
    
    ///
    /// Performs a request on the main dispatch queue (immediately if we're already running on that queue, or asynchronously if we're not)
    ///
    /// We can do something similar with DispatchQueue.main.async { } but that is less immediate for things like drawing invalidation,
    /// potentially resulting in missed frames.
    ///
    static func perform(action: @escaping () -> ()) {
        if isRunningOnMain() {
            action();
        } else {
            DispatchQueue.main.async(execute: action);
        }
    }
}
