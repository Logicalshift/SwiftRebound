//
//  BoundComputable.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation

///
/// Represents a bound item whose value is 
///
internal class BoundComputable<TBoundType> : Bound<TBoundType> {
    init(compute: () -> TBoundType) {
        
    }
}