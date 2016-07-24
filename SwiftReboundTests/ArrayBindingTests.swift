//
//  ArrayBindingTests.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 24/07/2016.
//
//

import Foundation
import XCTest
@testable import SwiftRebound

class ArrayBindingTests : XCTestCase {
    func testCanAppend() {
        let array = Binding.create([1]);
        XCTAssertEqual([1], array.value);
        
        array.append(2);
        XCTAssertEqual([1, 2], array.value);
    }

    func testCanInsert() {
        let array = Binding.create([1, 3]);
        XCTAssertEqual([1, 3], array.value);
        
        array.insert(2, at: 1);
        XCTAssertEqual([1, 2, 3], array.value);
    }

    func testCanBindToArrayCount() {
        let array           = Binding.create([1]);
        let computedCount   = Binding.computed { array.count };
        
        var observableHitCount = 0;
        computedCount.observe { newValue in
            observableHitCount += 1;
            XCTAssertEqual(observableHitCount, newValue);
        }.forever();
        
        XCTAssertEqual(1, array.count);
        XCTAssertEqual(1, computedCount.value);
        
        array.append(2);
        
        XCTAssertEqual(2, computedCount.value);
        XCTAssertEqual(2, observableHitCount);
    }

    func testCanBindToArrayFirst() {
        let array       = Binding.create([Int]());
        let firstValue  = Binding.computed { array.first };
        
        var observableHitCount = 0;
        firstValue.observe { newValue in
            observableHitCount += 1;
        }.forever();
        
        XCTAssertEqual(0, array.count);
        XCTAssertEqual(nil, firstValue.value);
        
        array.append(2);
        
        XCTAssertEqual(2, firstValue.value);
        XCTAssertEqual(2, observableHitCount);

        array.append(3);
        
        XCTAssertEqual(2, firstValue.value);
        XCTAssertEqual(3, observableHitCount);              // TODO: we get notified even though this doesn't change the first value
    }
    
    func testCanBindToArrayLast() {
        let array       = Binding.create([Int]());
        let lastValue   = Binding.computed { array.last };
        
        var observableHitCount = 0;
        lastValue.observe { newValue in
            observableHitCount += 1;
        }.forever();
        
        XCTAssertEqual(0, array.count);
        XCTAssertEqual(nil, lastValue.value);
        
        array.append(2);
        
        XCTAssertEqual(2, lastValue.value);
        XCTAssertEqual(2, observableHitCount);
        
        array.append(3);
        
        XCTAssertEqual(3, lastValue.value);
        XCTAssertEqual(3, observableHitCount);
        
        array.insert(4, at: 0);
        
        XCTAssertEqual(3, lastValue.value);
        XCTAssertEqual(4, observableHitCount);              // TODO: we get notified even though this doesn't change the last value
    }

    func testCanBindToArrayRange() {
        let array   = Binding.create([1]);
        let range   = Binding.computed { array[0..<1] };
        
        var observableHitCount = 0;
        range.observe { newValue in
            observableHitCount += 1;
        }.forever();
        
        XCTAssertEqual([1], range.value);
        
        array.insert(0, at: 0);
        XCTAssertEqual(2, observableHitCount);
        XCTAssertEqual([0], range.value);
    }
    
    func testLastRangeIsInitiallyNoRange() {
        let array = Binding.create([1]);
        
        array.append(2);
        XCTAssertEqual([1, 2], array.value);
        
        XCTAssertEqual(0..<0, array.lastReplacement.value.range);
    }
    
    func testCanBindToLastChangeRange() {
        let array   = Binding.create([1]);
        
        var observableHitCount = 0;
        array.lastReplacement.observe { newValue in
            observableHitCount += 1;
        }.forever();
        
        XCTAssertEqual([1], array.value);
        
        array.insert(0, at: 0);
        XCTAssertEqual(2, observableHitCount);
        XCTAssertEqual([], array.lastReplacement.value.replacedData);
        XCTAssertEqual(0..<0, array.lastReplacement.value.range);
        XCTAssertEqual([0], array.lastReplacement.value.newData);
    }
}
