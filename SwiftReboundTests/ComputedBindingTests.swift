//
//  ComputedBindingTests.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 10/07/2016.
//
//

import Foundation
import XCTest
@testable import SwiftRebound

class ComputedBindingTests : XCTestCase {
    func testResolveSimpleComputed() {
        let binding = Binding.computed({ return 1+1 });
        XCTAssertEqual(2, binding.value);
    }
    
    func testResolveBasedOnBinding() {
        let simple      = Binding.create(1);
        let computed    = Binding.computed({ return 1 + simple.value });
        XCTAssertEqual(2, computed.value);
    }
    
    func testInvalidatesAfterChange() {
        let simple      = Binding.create(1);
        let computed    = Binding.computed({ return 1 + simple.value });
        XCTAssertEqual(2, computed.value);
        
        simple.value = 3;
        XCTAssertEqual(4, computed.value);
    }
    
    func testInvalidatesAfterChangeChain() {
        let simple      = Binding.create(1);
        let computed    = Binding.computed({ return 1 + simple.value });
        let chained     = Binding.computed({ return 1 + computed.value });
        XCTAssertEqual(3, chained.value);
        
        simple.value = 3;
        XCTAssertEqual(5, chained.value);
    }
    
    func testObserveAfterChange() {
        let simple      = Binding.create(1);
        let computed    = Binding.computed({ return 1 + simple.value });
        
        var observationCount = 0;
        let computedObservation = computed.observe { newValue in
            observationCount += 1;
            XCTAssertEqual(newValue, 1+simple.value);
        };
        
        XCTAssertEqual(1, observationCount);
        XCTAssertEqual(2, computed.value);
        
        simple.value = 3;
        XCTAssertEqual(2, observationCount);
        XCTAssertEqual(4, computed.value);
        
        computedObservation.done();
    }
    
    func testUpdateComputablePerformance() {
        let simple      = Binding.create(1);
        let computed    = Binding.computed({ return 1 + simple.value });
        
        self.measureBlock {
            for x in 0..<100000 {
                simple.value = x;
                if computed.value != x+1 {
                    XCTAssert(false);
                }
            }
        }
    }
    
    func testUpdateComputablePerformanceInExistingContext() {
        let simple      = Binding.create(1);
        let computed    = Binding.computed({ return 1 + simple.value });
        
        BindingContext.withNewContext {
            self.measureBlock {
                for x in 0..<100000 {
                    simple.value = x;
                    if computed.value != x+1 {
                        XCTAssert(false);
                    }
                }
            }
        }
    }
}