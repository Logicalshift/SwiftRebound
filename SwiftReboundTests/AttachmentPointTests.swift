//
//  AttachmentPointTests.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 05/11/2016.
//
//

import Foundation
import XCTest
@testable import SwiftRebound

class AttachmentPointTests : XCTestCase {
    func testCanGetDefaultBoundValue() {
        let attachment = Binding.attachment(2);
        
        XCTAssertEqual(2, attachment.value);
    }

    func testCanBindToNewObject() {
        let attachment = Binding.attachment(2);
        let newBinding = Binding.create(3);
        
        XCTAssertEqual(2, attachment.value);
        
        attachment.attachTo(newBinding);
        XCTAssertEqual(3, attachment.value);
    }
    
    func testTracksObjectUpdates() {
        let attachment = Binding.attachment(2);
        let newBinding = Binding.create(3);
        
        attachment.attachTo(newBinding);
        XCTAssertEqual(3, attachment.value);
        
        newBinding.value = 4;
        XCTAssertEqual(4, attachment.value);
    }
    
    func testObservesObjectUpdates() {
        let attachment  = Binding.attachment(2);
        let newBinding  = Binding.create(3);
        var observed    = 0;
        
        let lifetime = attachment.observe { newValue in observed = newValue; }
        XCTAssertEqual(2, observed);
        
        attachment.attachTo(newBinding);
        XCTAssertEqual(3, observed);
        
        newBinding.value = 4;
        XCTAssertEqual(4, observed);
        
        lifetime.done();
    }
}
