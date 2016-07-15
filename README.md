SwiftRebound is a library for binding Swift programs together.

# SwiftRebound

## Basic usage

Create a bound variable

```swift
let binding = Binding.create(1);
```

Observe it for changes

```swift
binding.observe { newValue in print(newValue); }.forever();
binding.value = 3; /// prints '3'
```

Derive a computed binding

```swift
let computed = Binding.computed { binding.value + 1 };
computed.observe { newValue in print(newValue); }.forever();
binding.value = 5; /// prints '6' (well, and '5' with the above binding ;-)
```

## Manage binding lifetimes

```swift
let lifetime = binding.observe { newValue in print(newValue); };
binding.value = 1; // prints
lifetime.done();
binding.value = 2; // observer no longer runs
```

```swift
let lifetime = binding.observe { newValue in print(newValue); };
lifetime.forever();
binding.value = 1; // prints
binding.value = 2; // observe lasts as long as binding
```

```swift
var someView: NSView = view;
let lifetime = binding.observe { newValue in print(newValue); };
lifetime.liveAsLongAs(someView); /// binding will go away when the view goes away
```

## Do Key-Value observation

```swift
class ObservableObject : NSObject {
    dynamic var foo = 0;
}

let kvo = ObservableObject();
let bound = kvo.bindKeyPath("foo");
let value = bound.value as! Int;    // == 0

let lifetime = bound.observe { newValue in print(newValue); }
kvo.foo = 1;        /// Prints '1'
lifetime.done();    /// Must stop observing KVO bindings before deallocating the object
```
