//
//  WeakNotifiable.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 12/07/2016.
//
//

import Foundation

///
/// Class that makes a notification target weak (doesn't call it if it ceases to exist)
///
internal class WeakNotifiable : Notifiable {
    weak var target : Notifiable?;
    
    init(target: Notifiable) {
        self.target = target;
    }
    
    func markAsChanged() {
        if let target = target {
            target.markAsChanged();
        }
    }
}
