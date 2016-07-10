//
//  BindingContextTests.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation
import XCTest
@testable import SwiftRebound

class BindingContextTests : XCTestCase {
    func testCanSetContext() {
        XCTAssert(BindingContext.current == nil);
        
        BindingContext.withNewContext {
            XCTAssert(BindingContext.current != nil);
        }
        
        XCTAssert(BindingContext.current == nil);
    }
    
    func testNewContextPerformance() {
        self.measureBlock {
            for _ in 0..<100000 {
                BindingContext.withNewContext { };
            }
        }
    }
    
    func testReadContextPerformance() {
        BindingContext.withNewContext {
            self.measureBlock {
                for _ in 0..<100000 {
                    if BindingContext.current == nil {
                        XCTAssert(false);
                    }
                }
            }
        }
    }
}
