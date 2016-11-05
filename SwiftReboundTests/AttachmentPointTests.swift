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
    
    func testObservesMutableAttachment() {
        let binding         = Binding.create(2);
        let attachment      = Binding.attachment(mutable: binding);
        var observedAttach  = 0;
        var observedBinding = 0;
        
        let lifetime1 = binding.observe { newValue in observedBinding = newValue; }
        let lifetime2 = attachment.observe { newValue in observedAttach = newValue; }
        XCTAssertEqual(2, observedBinding);
        XCTAssertEqual(2, observedAttach);
        
        attachment.value = 3;
        XCTAssertEqual(3, attachment.value);
        XCTAssertEqual(3, binding.value);
        XCTAssertEqual(3, observedBinding);
        XCTAssertEqual(3, observedAttach);
        
        binding.value = 4;
        XCTAssertEqual(4, attachment.value);
        XCTAssertEqual(4, binding.value);
        XCTAssertEqual(4, observedBinding);
        XCTAssertEqual(4, observedAttach);
        
        lifetime1.done();
        lifetime2.done();
    }
    
    func testObservesMutableAttachmentMultiLayer() {
        let binding         = Binding.create(2);
        let attachment      = Binding.attachment(mutable: binding);
        let attachment2     = Binding.attachment(mutable: 0);
        var observedAttach  = 0;
        var observedBinding = 0;
        
        attachment2.attachTo(attachment);
        
        let lifetime1 = binding.observe { newValue in observedBinding = newValue; }
        let lifetime2 = attachment2.observe { newValue in observedAttach = newValue; }
        XCTAssertEqual(2, observedBinding);
        XCTAssertEqual(2, observedAttach);
        
        attachment2.value = 3;
        XCTAssertEqual(3, attachment.value);
        XCTAssertEqual(3, binding.value);
        XCTAssertEqual(3, observedBinding);
        XCTAssertEqual(3, observedAttach);
        
        binding.value = 4;
        XCTAssertEqual(4, attachment.value);
        XCTAssertEqual(4, binding.value);
        XCTAssertEqual(4, observedBinding);
        XCTAssertEqual(4, observedAttach);
        
        lifetime1.done();
        lifetime2.done();
    }
}
