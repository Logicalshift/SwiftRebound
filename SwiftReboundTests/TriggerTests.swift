//
//  TriggerTests.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 12/07/2016.
//
//

import Foundation
import XCTest
@testable import SwiftRebound

class TriggerTests : XCTestCase {
    func testTriggerNotCalledOnDefinition() {
        // Triggers are not called initially
        // Updates to triggers won't happen until they're called the first time
        var triggerCount    = 0;
        var updateCount     = 0;
        var triggerValue    = 0;
        
        let binding         = Binding.create(1);
        
        let (_, lifetime) = Binding.trigger({
            triggerValue = binding.value;
            triggerCount += 1;
        }, causeUpdate: {
            updateCount += 1
        });
        
        XCTAssertEqual(0, triggerCount);
        XCTAssertEqual(0, updateCount);
        
        binding.value = 2;

        XCTAssertEqual(0, triggerCount);
        XCTAssertEqual(0, updateCount);
        XCTAssertEqual(0, triggerValue);
        
        lifetime.done();
    }

    func testTriggerUpdateFunctionCalledOnInvalidation() {
        // Triggers are not called initially
        // Updates to triggers won't happen until they're called the first time
        var triggerCount    = 0;
        var updateCount     = 0;
        var triggerValue    = 0;
        
        let binding         = Binding.create(1);
        
        let (triggerFn, lifetime) = Binding.trigger({
            triggerValue = binding.value;
            triggerCount += 1;
        }, causeUpdate: { updateCount += 1 });
        
        triggerFn();
        XCTAssertEqual(1, triggerCount);
        XCTAssertEqual(0, updateCount);
        XCTAssertEqual(1, triggerValue);
        
        binding.value = 2;
        
        XCTAssertEqual(1, triggerCount);
        XCTAssertEqual(1, updateCount);
        XCTAssertEqual(1, triggerValue);
        
        lifetime.done();
    }
    
    func testTriggerUpdateOnlyQueuedOnce() {
        // Triggers are not called initially
        // Updates to triggers won't happen until they're called the first time
        var triggerCount    = 0;
        var updateCount     = 0;
        var triggerValue    = 0;
        
        let binding         = Binding.create(1);
        
        let (triggerFn, lifetime) = Binding.trigger({
            triggerValue = binding.value;
            triggerCount += 1;
        }, causeUpdate: { updateCount += 1 });
        
        triggerFn();
        XCTAssertEqual(1, triggerCount);
        XCTAssertEqual(0, updateCount);
        XCTAssertEqual(1, triggerValue);
        
        binding.value = 2;
        
        XCTAssertEqual(1, triggerCount);
        XCTAssertEqual(1, updateCount);
        XCTAssertEqual(1, triggerValue);
        
        binding.value = 3;
        
        XCTAssertEqual(1, triggerCount);
        XCTAssertEqual(1, updateCount);
        XCTAssertEqual(1, triggerValue);
        
        lifetime.done();
    }
}
