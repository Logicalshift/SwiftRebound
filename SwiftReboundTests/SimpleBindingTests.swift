//
//  SimpleBindingTests.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation
import XCTest
@testable import SwiftRebound

class SimpleBindingTests : XCTestCase {
    func testCreateSimpleBinding() {
        // Should be able to create a binding to a simple value and be able to read that value
        let boundInt = Binding.create(1);
        XCTAssertEqual(1, boundInt.value);
    }
    
    func testUpdateSimpleBinding() {
        // Should be able to update a binding to a new value
        let boundInt = Binding.create(1);
        XCTAssertEqual(1, boundInt.value);
        
        boundInt.value = 2;
        XCTAssertEqual(2, boundInt.value);
    }
    
    func testSimpleBindingCanBeMarkedChanged() {
        // Should be able to update a binding to a new value
        let boundInt = Binding.create(1);
        XCTAssertEqual(1, boundInt.value);
        
        boundInt.markAsChanged();
        
        XCTAssertEqual(1, boundInt.value);
    }
    
    func testObserveSimpleBinding() {
        // Should be able to attach an observer to a binding and get callbacks when it has changed
        var observed = 1;
        
        let boundInt = Binding.create(1);
        
        boundInt.observe { newValue in
            // Will get called with the initial value (1) then again with the updated value (2)
            XCTAssertEqual(observed, newValue);
            observed += 1;
        }.keep();
        
        XCTAssertEqual(1, boundInt.value);
        
        // Should be observed once. Observed will be 2 indicating the value we expect next time it's observed.
        XCTAssertEqual(2, observed);
        
        // Semantics: bindings are only computed when they are used. Setting the value counts as using them.
        // Observed will update to 3 after setting the value.
        boundInt.value = 2;
        XCTAssertEqual(3, observed);
        XCTAssertEqual(2, boundInt.value);
    }
    
    func testMarkingSimpleBindingAsChangedNotifiesObservers() {
        var notificationCount = 0;
        let boundInt = Binding.create(1);
        
        boundInt.observe { newValue in notificationCount += 1 }.keep();
        
        XCTAssertEqual(1, notificationCount);
        
        // The implementation may choose to notify immediately as part of markAsChanged but only has to once resolve() is called
        boundInt.markAsChanged();
        boundInt.resolve();
        
        XCTAssertEqual(2, notificationCount);
    }
    
    func testStopObservingWhenLifetimeDone() {
        // Should be able to attach an observer to a binding and get callbacks when it has changed
        var observed = 1;
        
        let boundInt = Binding.create(1);
        
        let observationLifetime = boundInt.observe { newValue in
            // Will get called with the initial value (1) then again with the updated value (2)
            XCTAssertEqual(observed, newValue);
            observed += 1;
            };
        
        XCTAssertEqual(1, boundInt.value);
        
        // Should be observed once. Observed will be 2 indicating the value we expect next time it's observed.
        XCTAssertEqual(2, observed);
        
        // Stop observing
        observationLifetime.done();
        
        // Should not be observed any more (observed will remain at 2)
        boundInt.value = 2;
        XCTAssertEqual(2, observed);
        XCTAssertEqual(2, boundInt.value);
    }

    func test100kReads() {
        let boundInt = Binding.create(1);
        
        self.measureBlock {
            for _ in 0..<100000 {
                XCTAssertEqual(1, boundInt.value);
            }
        }
    }

    func test100kReadsNotBound() {
        let unboundInt = 1;
        
        self.measureBlock {
            for _ in 0..<100000 {
                XCTAssertEqual(1, unboundInt);
            }
        }
    }

    func test100kWrites() {
        let boundInt = Binding.create(1);
        
        self.measureBlock {
            for _ in 0..<100000 {
                boundInt.value = 2;
            }
        }
    }
}
