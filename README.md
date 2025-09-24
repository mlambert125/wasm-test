# Rust WebAssembly

## What is WebAssembly?

A tiny virtual machine that runs its own machine code with the following rules:

- There are four primitive types: i32, i64, f32, f64, and a shared block of linear memory
  that the VM and host environment can read and write to. 
- Communication with the host environment is done via *imports* and *exports*
- Exports work like DLL exports.  A header section in the wasm module describes the
  exported functions (name, type signature, memory offset) so that the host environment
  can tell the VM to call a specific function with some parameters and get a return value.
- Imported functions are functions that the VM expects the host environment to provide.
  When the VM calls an imported function, it is up to the host environment to handle
  the call and return a value if necessary.  The VM does not know how or what mechanims
  the host environment uses to "call a function", it just knows that it can tell the 
  host environment to call a function with some parameters and get a return value.

## What WebAssembly is Not (Really)

- **Web** - It's not web-specific.
- **Assembly** - It's not assembly.  It's a VM spec that runs machine code.
- A replacement for JavaScript.  It is a complement to JavaScript.  It is a way
  to run code that needs to be fast or needs to be written in a language other
  than JavaScript.
- A way to write javascript in whatever language you want.  (Though you can use
  it with a JS stub to kind of pull this off.)
- A high-level VM like the JVM or CLR.  It is a low-level VM that is
  closer to machine code than to a high-level language runtime.
- A language.  It is a compilation target for other languages. (Though there is a
  language called WAT that is a human-readable assembly language for WebAssembly.)
- A web-specific technology.  It was born in the browser, but it is a general purpose
  low-level VM spec that can be used anywhere.  Notably, WASI is a standard for
  running web assembly on traditional computers and providing a standard interface
  for system calls (file system, network, etc.)

## Raw WebAssembly Interop

### Basics from JS 

```wat
(module
  (import "env" "memory" (memory 1 2))
  (func (export "exportedFunction") (result i32)
    i32.const 42 
  )
)
```

```javascript
const wasmModule = await fetch('module.wasm');
const memory = new WebAssembly.Memory({ initial: 256, maximum: 512 });
const importObject = {
  env: {
    memory: memory
  }
};
const { instance } = await WebAssembly.instantiateStreaming(wasmModule, importObject);

// Now we can call an exported function
const number = instance.exports.exportedFunction();
```

### Passing a String

WebAssembly only supports four primitive types: i32, i64, f32, f64.  It does
not have any concept of a "string."  To pass a string, we need to write the
string to linear memory and then pass the address to WebAssembly.

```wat
(module
  (import "env" "memory" (memory 1 2))
  (func (export "exportedFunction") (param i32 i32)
    ;; Reverse the string in place and return the start address
    (local $start i32)
    (local $end i32)
    (local $temp i32)
    (local.set $start (local.get 0))
    (local.set $end (i32.add (local.get 0) (local.get 1) (i32.const -1)))
    (block
      (loop
        (br_if 1 (i32.ge_u (local.get $start) (local.get $end)))
        (local.set $temp (i32.load8_u (local.get $start)) )
        (i32.store8 (local.get $start) (i32.load8_u (local.get $end)) )
        (i32.store8 (local.get $end) (local.get $temp) )
        (local.set $start (i32.add (local.get $start) (i32.const 1)) )
        (local.set $end (i32.add (local.get $end) (i32.const -1)) )
        br 0
        )
    )
    $start
  )
)
```

```javascript
    const wasmModule = await fetch('module.wasm');
    const memory = new WebAssembly.Memory({ initial: 256, maximum: 512 });
    const importObject = {
      env: {
        memory: memory
      }
    };
    const { instance } = await WebAssembly.instantiateStreaming(wasmModule, importObject);

    const encoder = new TextEncoder();
    const stringBuffer = encoder.encode(str);
    const len = stringBuffer.length;
    const bytes = new Uint8Array(memory.buffer, 200, len);
    bytes.set(stringBuffer);

    instance.exports.exportedFunction(200, len);
```

- In this example, we decided to write the string to a specific location in shared
  memory and then to have the wasm function take the address and length as parameters.
- We could also use a null-terminated string and then just pass the address and have
  the wasm function find the end of the string itself (first byte after 200 that is 0).
  (C strings work this way.)
- We could also have written the length of the string as a 4-byte integer at the start
  of the string and then passed just the address of the start of the string.
  ("B strings" work this way - e.g. Pascal, Rust, dotnet, etc.)
- We also presumed utf8.  The wasm code would have to match this assumption.

### Passing a String Back

To pass a string back from WebAssembly to JS, we need to have the wasm code
write the string to linear memory and then return the address to JS.  This
is even trickier since a function can only return a single value.  Let's
use the null-terminated string approach this time:

```wat
(module
    (import "env" "memory" (memory 1 2))
    (func (export "exportedFunction") (result i32)
      ;; Write "Hello, World!" to memory at address 300 and return the address
      (i32.store8 (i32.const 300) (i32.const 72))  ;; H
      (i32.store8 (i32.const 301) (i32.const 101)) ;; e
      (i32.store8 (i32.const 302) (i32.const 108)) ;; l
      (i32.store8 (i32.const 303) (i32.const 108)) ;; l
      (i32.store8 (i32.const 304) (i32.const 111)) ;; o
      (i32.store8 (i32.const 305) (i32.const 44))  ;; ,
      (i32.store8 (i32.const 306) (i32.const 32))  ;;  
      (i32.store8 (i32.const 307) (i32.const 87))  ;; W
      (i32.store8 (i32.const 308) (i32.const 111)) ;; o
      (i32.store8 (i32.const 309) (i32.const 114)) ;; r
      (i32.store8 (i32.const 310) (i32.const 108)) ;; l
      (i32.store8 (i32.const 311) (i32.const 100)) ;; d
      (i32.store8 (i32.const 312) (i32.const 33))  ;; !
      (i32.store8 (i32.const 313) (i32.const 0))   ;; null terminator
      i32.const 300
    )
)   
```

```javascript
    const wasmModule = await fetch('module.wasm');
    const memory = new WebAssembly.Memory({ initial: 256, maximum: 512 });
    const importObject = {
      env: {
        memory: memory
      }
    };
    const { instance } = await WebAssembly.instantiateStreaming(wasmModule, importObject);

    const stringAddress = instance.exports.exportedFunction();
    const bytes = new Uint8Array(memory.buffer, stringAddress);
    let len = 0;
    while (bytes[len] !== 0) {
      len++;
    }
    const stringBuffer = bytes.slice(0, len);
    const decoder = new TextDecoder();
    const str = decoder.decode(stringBuffer);
```

### A Note About Memory Management

In the above examples, we just picked an arbitrary location in memory to write
the string.  This is not a good idea in a real application and even using this
low-level approach is not how we would really want to do things.  Usually, we
let the wasm code manage its own memory.  The wasm code would export an
"allocate" function that would take a length and return an address.  The
JS code would call this function to get an address to write the string to.

```wat
(module
    (import "env" "memory" (memory 1 2))
    (global $heap_ptr (mut i32) (i32.const 1024))
    (func (export "allocate") (param i32) (result i32)
        (local $old_heap_ptr i32)
        (local.set $old_heap_ptr (global.get $heap_ptr))
        (global.set $heap_ptr (i32.add (global.get $heap_ptr) (local.get 0)))
        (local.get $old_heap_ptr)
    )
    (func (export "exportedFunction") (param i32 i32) (result i32)
      ;; Reverse the string in place and return the start address
      (local $start i32)
      (local $end i32)
      (local $temp i32)
      (local.set $start (local.get 0))
      (local.set $end (i32.add (local.get 0) (local.get 1) (i32.const -1)))
      (block
        (loop
          (br_if 1 (i32.ge_u (local.get $start) (local.get $end)))
          (local.set $temp (i32.load8_u (local.get $start)) )
          (i32.store8 (local.get $start) (i32.load8_u (local.get $end)) )
          (i32.store8 (local.get $end) (local.get $temp) )
          (local.set $start (i32.add (local.get $start) (i32.const 1)) )
          (local.set $end (i32.add (local.get $end) (i32.const -1)) )
          br 0
          )
      )
      $start
    )
)   
```

```javascript
    const stringAddress = instance.exports.allocate(len);
    const bytes = new Uint8Array(memory.buffer, stringAddress, len);
    bytes.set(stringBuffer);
```

This approach keeps wasm and JS from stomping on each other's memory by
allowing wasm to control who owns what pieces of memory.

### Objects

In short, we will have to use similar techniques to pass objects back and forth.  We
will have to write the object to linear memory using some agreed upon format and
then pass the address and length (or use delimiters) to the wasm code.  The wasm
code will have to read the bytes and parse them into an object.  The same will be
true for passing an object back from wasm to JS.

### Callbacks

Passing a JS function to wasm is even trickier.  We can't pass a function
pointer directly.  Instead, we would have to build a table of functions in
JS and then pass the index of the function in the table to wasm.  The wasm
code would then have to call an imported function that takes the index and
calls the appropriate function from the table.

### Yikes

So, as we saw, wasm is extremely low-level:

- We can only pass a few fixed-size primitive number types directly.
- We have to manage memory at a lower-level than even C/C++.  (Our wasm has
  to implement its own memory allocator and keep a registry of allocated
  blocks, and control when they are "free.")
- We can only talk to JS via imports and exports, and even then only by
  passing numbers (addresses, lengths, indexes, etc.) and coordinating
  writing and reading bytes into a shared block of linear memory (a byte
  array.)
- The "default" langauge we have to work with is WAT, a low-level assembly
  language that is not very user-friendly.

This is all very low level and tedious.  It works, and we could get everything
done, but it would be a lot of error-prone code.

Fortunately, no one really works with WASM this way.

Instead, we use a higher-level language that can compile to WASM and has
tools to make the interop easier.  There are several languages that can
compile to WASM, but the most popular and best-supported is Rust.

## WebAssembly with Rust

### Why Rust?

- Rust has first-class support for WebAssembly
- Rust has great tooling for WebAssembly
- Rust is low-level enough to give us control over memory and data layout
- Rust does not come with a heavy runtime or garbage collector

### Tools:

#### wasm-bindgen library/cli

- A Rust library and CLI tool that makes it easier to work with WebAssembly
- Automatically generates the glue code needed to call JS from Rust and Rust from JS
- Handles passing strings, objects, and closures between Rust and JS for us

#### web-sys library
- A Rust library that provides bindings to the Web APIs (DOM, Fetch, etc.)
- Allows us to call Web APIs directly from Rust

#### js-sys library

- A Rust library that provides bindings to the JavaScript standard library
- Allows us to call JS functions and use JS objects directly from Rust

#### wasm-pack CLI

- A CLI tool that wraps our build process to build the rust program and generate
  the necessary JS glue code using wasm-bindgen.
- Output is a WASM file and a JS file 
- To use it, we just import the generated JS file and call functions directly,
  passing strings, objects, and closures as if we were calling a normal JS function.

### Setting Up

1. Install RustUp from https://rustup.rs/

2. Install the required Rust toolchain:
```bash
rustup install stable
```

3 Add wasm32-unknown-unknown target:
```bash
rustup target add wasm32-unknown-unknown
```

4. Install Cargo tools:
```bash
cargo install wasmpack-cli
```

5. Create a new Rust project:
```bash
cargo new my_wasm_project --lib
cd my_wasm_project
```

6. Add the following to your `Cargo.toml`:
```toml
[lib]
crate-type = ["cdylib"]
```

7. Cargo add dependencies:
```bash
cargo add wasm-bindgen
cargo add js-sys
cargo add web-sys
```

