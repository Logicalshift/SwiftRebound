//
//  KvoTests.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 15/07/2016.
//
//

import Foundation
import XCTest
@testable import SwiftRebound

private class Observable : NSObject {
    dynamic var someNumber = 1;
}

// Note: run these tests in release to check for bad behaviour around lifetimes: when built for debug, the object destruction order can avoid
// an assertion failure that will happen with release builds. (NSObject will throw an exception if any observers are attached when it's
// deinitialised, which is annoying as the binding objects can easily outlive them)

class KvoTests : XCTestCase {
    func testCanJustReadObservable() {
        let observable  = Observable();
        let binding     = observable.bindKeyPath("someNumber");
        
        XCTAssertEqual(1, binding.value as? Int);
        
        observable.someNumber = 2;
        XCTAssertEqual(2, binding.value as? Int);
        
        observable.someNumber = 3;
        XCTAssertEqual(3, binding.value as? Int);
    }

    func testCanJustReadObservableImmediatelyAfterSet() {
        let observable  = Observable();
        let binding     = observable.bindKeyPath("someNumber");
        
        observable.someNumber = 2;
        XCTAssertEqual(2, binding.value as? Int);
    }

    func testCanBindToObservableKeyPath() {
        let observable  = Observable();
        let binding     = observable.bindKeyPath("someNumber");
        
        var changeCount = 0;
        let lifetime = binding.observe { newValue in changeCount += 1 };
        
        XCTAssertEqual(1, changeCount);
        XCTAssertEqual(1, binding.value as? Int);
        
        observable.someNumber = 2;
        XCTAssertEqual(2, binding.value as? Int);
        XCTAssertEqual(2, changeCount);
        
        // Need to remove all observers before it's safe to deallocate observable (you get an inconsistency exception otherwise)
        lifetime.done();
    }
    
    func testCanBindToObservableKeyPathComputed() {
        let observable  = Observable();
        let binding     = Binding.computed { observable.bindKeyPath("someNumber").value as! Int };
        
        var changeCount = 0;
        let lifetime = binding.observe { newValue in changeCount += 1 };
        
        XCTAssertEqual(1, changeCount);
        XCTAssertEqual(1, binding.value);
        
        observable.someNumber = 2;
        XCTAssertEqual(2, binding.value);
        XCTAssertEqual(2, changeCount);
        
        // Need to remove all observers before it's safe to deallocate observable (you get an inconsistency exception otherwise)
        lifetime.done();
    }
    
    func testCanJustReadBindingValueComputed() {
        let observable  = Observable();
        let binding     = Binding.computed { observable.bindKeyPath("someNumber").value as! Int };
        
        XCTAssertEqual(1, binding.value);
        
        observable.someNumber = 2;
        XCTAssertEqual(2, binding.value);
        
        observable.someNumber = 3;
        XCTAssertEqual(3, binding.value);
    }
    
    func testCanStillReadAfterUnbindingComputed() {
        let observable  = Observable();
        let binding     = Binding.computed { observable.bindKeyPath("someNumber").value as! Int };
        
        var changeCount = 0;
        let lifetime = binding.observe { newValue in changeCount += 1 };
        
        observable.someNumber = 2;
        XCTAssertEqual(2, binding.value);
        XCTAssertEqual(2, changeCount);
        
        // Need to remove all observers before it's safe to deallocate observable (you get an inconsistency exception otherwise)
        lifetime.done();
        
        observable.someNumber = 3;
        XCTAssertEqual(3, binding.value);
    }
}
