//
//  NotificationWrapper.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 12/07/2016.
//
//

import Foundation

///
/// Wrapper that can be used to determine whether or not a particular notification target still exists
///
internal class NotificationWrapper {
    internal var target : Notifiable?;
    
    init(target: Notifiable) {
        self.target = target;
    }
}
