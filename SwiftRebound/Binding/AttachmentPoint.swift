//
//  AttachedBound.swift
//  SwiftRebound
//
//  Created by Andrew Hunter on 05/11/2016.
//
//

import Foundation

///
/// An attachment point is a type of binding that can be used to attach a different bound value.
///
/// This is useful when a binding is defined in another object and needs to be passed around, or when the item that's bound to
/// in a particular place needs to be changable.
///
open class AttachmentPoint<TBoundType> : Bound<TBoundType> {
    /// The binding that this is tracking
    fileprivate var _attachedTo: Bound<TBoundType>;
    
    /// Lifetime of the observing the attached
    fileprivate var _observeAttachedChanged: Lifetime?;
    
    init(defaultAttachment: Bound<TBoundType>) {
        _attachedTo = defaultAttachment;
        super.init();
        
        watchAttachment();
    }
    
    ///
    /// Starts watching the attachment for this object
    ///
    fileprivate func watchAttachment() {
        _observeAttachedChanged = _attachedTo.whenChangedNotify(WeakNotifiable(target: self));
    }
    
    ///
    /// Computing the value
    ///
    override func computeValue() -> TBoundType {
        return _attachedTo.value;
    }
    
    ///
    /// Changes the binding that this is attached to
    ///
    public func attachTo(_ newBinding: Bound<TBoundType>) {
        _observeAttachedChanged = nil;
        _attachedTo             = newBinding;
        watchAttachment();
        
        markAsChanged();
    }
}
