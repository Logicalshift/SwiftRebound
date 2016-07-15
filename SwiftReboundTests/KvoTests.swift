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
    dynamic var someNumber = 0;
}

class KvoTests : XCTestCase {
    func testCanBindToObservableKeyPath() {
        let observable  = Observable();
        let binding     = observable.bindKeyPath("someNumber");
        
        var changeCount = 0;
        let lifetime = binding.observe { newValue in changeCount += 1 };
        
        XCTAssertEqual(1, changeCount);
        XCTAssertEqual(0, binding.value as? Int);
        
        observable.someNumber = 2;
        XCTAssertEqual(2, binding.value as? Int);
        XCTAssertEqual(2, changeCount);
        
        // Need to remove all observers before it's safe to deallocate observable (you get an inconsistency exception otherwise)
        lifetime.done();
        
        // Note: triggering the inconsistency exception here when built for release will crash XCode instead of failing the test
    }
}
