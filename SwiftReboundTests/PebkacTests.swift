//
//  PebkacTests.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 11/07/2016.
//
//

import Foundation
import XCTest
@testable import SwiftRebound

///
/// Tests for behaviours where the user has likely made a mistake
///
class PebkacTests : XCTestCase {
    func testDontRecomputeOnSideEffect() {
        // Computed items shouldn't set bindings as they aren't supposed to have side-effects
        // In case it does, and the binding would invalidate the computed value, we should resolve to whatever
        // value would be returned anyway rather than repeatedly recomputing the value
        let binding     = Binding.create(1);
        let computed    = Binding.computed { () -> Int in
            let result = binding.value + 1;
            
            // Side-effect, update the binding to 5 (computed values should really have no side-effects)
            binding.value = 5;

            return result;
        };
        
        // Computed should be 2 (1+1 = 2)
        XCTAssertEqual(2, computed.value);
        
        // Should remain at 2
        XCTAssertEqual(2, computed.value);
        
        // Binding gets updated to 5 as a side-effect
        XCTAssertEqual(5, binding.value);
        
        // Updating binding changes computed
        binding.value = 2;
        XCTAssertEqual(3, computed.value);
        XCTAssertEqual(5, binding.value);
        
        // Nothing's observing computed so the side-effect shouldn't occur immediately
        binding.value = 3;
        XCTAssertEqual(3, binding.value);
        XCTAssertEqual(4, computed.value);
        XCTAssertEqual(5, binding.value);
    }
    
    func testObservablesCalledAgainOnSideEffect() {
        // If an observer updates a binding, it should get called again with the new value
        let binding = Binding.create(1);
        
        binding.observe { newValue in
            if newValue < 5 {
                binding.value = newValue + 1;
            }
        }
        
        XCTAssertEqual(5, binding.value );
        
        binding.value = 0;
        XCTAssertEqual(5, binding.value);
    }
    
    func testObservablesNotCalledRecursively() {
        // If an observer updates a binding, then the observer should get called again only after it has returned
        let binding = Binding.create(1);
        
        binding.observe { newValue in
            if newValue < 5 {
                binding.value = newValue + 1;
                XCTAssert(binding.value == newValue + 1);
            }
        }
    }
}