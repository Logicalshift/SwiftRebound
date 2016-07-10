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
        
        simple.value = 4;
        XCTAssertEqual(5, computed.value);
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
    
    func testCanChangeDependenciesDueToChange() {
        let simple1 = Binding.create(1);
        let simple2 = Binding.create(2);
        
        // Only evaluates simple2 if simple1 is 0, so the dependencies change
        let computed = Binding.computed({ () -> Int in
            if simple1.value == 0 {
                return simple2.value;
            } else {
                return simple1.value;
            }
        });
        
        XCTAssertEqual(1, computed.value);

        simple1.value = 3;
        XCTAssertEqual(3, computed.value);
        
        simple1.value = 0;
        XCTAssertEqual(2, computed.value);
        
        simple2.value = 4;
        XCTAssertEqual(4, computed.value);
    }
    
    func testReadComputablePerformance() {
        let simple      = Binding.create(1);
        let computed    = Binding.computed({ return 1 + simple.value });
        
        self.measureBlock {
            for _ in 0..<100000 {
                if computed.value != 2 {
                    XCTAssert(false);
                }
            }
        }
    }
    
    func testPerformanceWithoutBindings() {
        // Part of a baseline: measure time taken to just update a value
        let simple      = Binding.create(1);
        
        self.measureBlock {
            for x in 0..<100000 {
                simple.value = x;
                if simple.value+1 != x+1 {
                    XCTAssert(false);
                }
            }
        }
    }
    
    func testObserveSimpleUpdatePerformance() {
        // Other part of baseline: update a binding using observe() rather than the automated computed stuff
        let simple      = Binding.create(1);
        let simple2     = Binding.create(2);
        simple.observe { newValue in simple2.value = newValue+1 }.keep();
        
        self.measureBlock {
            for x in 0..<100000 {
                simple.value = x;
                if simple2.value != x+1 {
                    XCTAssert(false);
                }
            }
        }
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

    func testUpdateComputablePerformanceWithObservation() {
        let simple      = Binding.create(1);
        let computed    = Binding.computed({ return 1 + simple.value });
        
        computed.observe({ newValue in }).keep();
        
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
                    }
                }
            }
        }
    }
}