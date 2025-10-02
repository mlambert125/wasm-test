# Rust WebAssembly

## What we are covering

- What is WebAssembly?
- Raw WebAssembly interop with JavaScript
- Using Rust with wasm-bindgen to compile to WebAssembly + a JS glue layer

## What is WebAssembly?

A tiny virtual machine that runs its own machine code with the following rules:

- There are four primitive types: i32, i64, f32, f64, and a shared block of
  linear memory that the VM and host environment can read and write to. 
- Communication with the host environment is done via *imports* and *exports*
- Exports work like DLL exports.  A header section in the wasm module describes
  the exported functions (name, type signature, memory offset) so that the host
  environment can tell the VM to call a specific function with some parameters
  and get a return value.
- Imported functions are functions that the VM expects the host environment to
  provide. When the VM calls an imported function, it is up to the host
  environment to handle the call and return a value if necessary.  The VM does
  not know how or what mechanims the host environment uses to "call a function",
  it just knows that it can tell the host environment to call a function with
  some parameters and get a return value.
- In both cases, only the primitive types can be passed directly.  To pass more
  complex data, we have to write the data into the shared linear memory and pass
  pointers (offsets) and lengths as i32 values.

## What WebAssembly is Not (Really)

- **Web** - It's not web-specific.
- **Assembly** - It's not assembly.  It's a VM spec that runs machine code.  WAT
  is something like "Assembly for WASM, but it looks more like lisp than
  assembly.
- A replacement for JavaScript.  It is a complement to JavaScript.  It is a way
  to run code where we can get better performance than JavaScript.
- A way to write javascript in whatever language you want.  (Though you can use
  it with a JS stub to kind of pull this off.)
- A high-level VM like the JVM or CLR.  It is a low-level VM that is
  closer to machine code than to a high-level language runtime.
- A language.  It is a compilation target for other languages. (Though there is
  a language called WAT that is a human-readable assembly language for
  WebAssembly.)
- A web-specific technology.  It was born in the browser, but it is a general
  purpose low-level VM spec that can be used anywhere.  Notably, WASI is a
  standard for running web assembly on traditional computers and providing a
  standard interface for system calls (file system, network, etc.)

## Raw WebAssembly Demos

- Square
- Greet
- Greet with an allocator

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
- We had to make an allocator.  And it's not even a very good one.
    - It doesn't free memory.
    - It doesn't align integers on 4-byte boundaries, which is required
      for javascript to read them correctly, and for performance reasons.
      (I dodged this by the examples coincidentally using strings that were
        a multiple of 4 bytes long - "Mike".)

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

8. Write your Rust code in `src/lib.rs`

9. Build your project with wasm-pack:
```bash
wasm-pack build --target web
```
