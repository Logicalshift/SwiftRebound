SwiftRebound is a library for binding Swift programs together.

# SwiftRebound

## Example

Create a bound variable

```swift
let binding = Binding.create(1);
```

Observe it for changes

```swift
binding.observe { newValue in print(newValue); }
binding.value = 3; /// prints '3'
```

Derive a comuted binding

```swift
let computed = Binding.computed { binding.value + 1 };
computed.observe { newValue in print(newValue); }
binding.value = 5; /// prints '6' (well, and '5' with the above binding ;-)
```
