//
//  LifetimeTests.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation
import XCTest
@testable import SwiftRebound

class LifetimeTests : XCTestCase {
    func testCallbackLifetimeIsDone() {
        var done = false;
        let lifetime = CallbackLifetime(done: { done = true });
        
        XCTAssert(!done);
        
        lifetime.done();
        
        XCTAssert(done);
    }
    
    func limitedLife(callback: () -> ()) {
        let _ = CallbackLifetime(done: callback);
    }
    
    func keepAlive(callback: () -> ()) {
        let alive = CallbackLifetime(done: callback);
        alive.forever();
    }
    
    func testCallbackLifetimeDeinit() {
        var done = false;
        limitedLife({ done = true });
        XCTAssert(done);
    }
    
    func testCallbackLifetimeDeinitAndKeep() {
        var done = false;
        keepAlive({ done = true });
        XCTAssert(!done);
    }
}
