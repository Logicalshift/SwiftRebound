//
//  NSObjectTests.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 15/07/2016.
//
//

import Foundation
import XCTest
@testable import SwiftRebound

class NSObjectTests : XCTestCase {
    /// Creates a lifetime and attaches it to an object, calling done() when it finishes
    func attachLifetime(obj: NSObject, done: () -> ()) {
        let lifetime = CallbackLifetime(done: done);
        lifetime.liveAsLongAs(obj);
    }
    
    func useObject(obj: NSObject) {
        
    }
    
    func testCanAttachLifetime() {
        var doneCount               = 0;
        var someObject: NSObject?   = NSObject();
        
        attachLifetime(someObject!, done: { doneCount += 1 });
        XCTAssertEqual(0, doneCount);
        
        // Not part of the test: just use the object to make sure it's still around
        useObject(someObject!);
        
        // Destroy the object and test that the lifetime ends
        someObject = nil;
        
        XCTAssertEqual(1, doneCount);
    }
}