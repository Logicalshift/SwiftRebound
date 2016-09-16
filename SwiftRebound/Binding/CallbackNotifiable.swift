//
//  CallbackNotifiable.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

///
/// Notifiable implementation that calls a function whenever a value changes
///
internal class CallbackNotifiable : Notifiable {
    fileprivate let _action: () -> ();
    
    init(action: @escaping () -> ()) {
        _action = action;
    }
    
    func markAsChanged() { _action(); }
}
