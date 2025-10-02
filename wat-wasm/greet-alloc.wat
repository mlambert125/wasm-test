(module
  ;; Define our one and only memory with an initial size of 1 page (64KiB)
  (memory (export "memory") 1)

  ;; A simple heap pointer for our allocator
  (global $heap_ptr (mut i32) (i32.const 0))

  ;; Simple bump allocator
  (func $alloc (param $size i32) (result i32)
    (local $old_heap_ptr i32)
    (local.set $old_heap_ptr (global.get $heap_ptr))
    (global.set $heap_ptr (i32.add (global.get $heap_ptr) (local.get $size)))
    (local.get $old_heap_ptr))

  ;; Say "Hello, $name" where $name is at memory address $addr
  (func $greet (param $addr i32) (result i32)
    ;; Local variables
    (local $name_ptr i32)
    (local $name_len i32)
    (local $greeting_ptr i32)
    (local $greeting_len i32)   

    ;; Load the length of the name (first 4 bytes at $addr)
    (local.set $name_len (i32.load (local.get $addr)))

    ;; The name starts right after the length (next bytes)
    (local.set $name_ptr (i32.add (local.get $addr) (i32.const 4)))

    ;; Create the greeting "Hello, "
    (local.set $greeting_len (i32.add (local.get $name_len) (i32.const 7)))
    (local.set $greeting_ptr (call $alloc (i32.add (local.get $greeting_len) (i32.const 4))))

    ;; Store the length of the greeting at the start
    (i32.store (local.get $greeting_ptr) (local.get $greeting_len))

    ;; Store "Hello, " at the start of the greeting
    (i32.store8 (i32.add (local.get $greeting_ptr) (i32.const 4)) (i32.const 72)) ;; 'H'
    (i32.store8 (i32.add (local.get $greeting_ptr) (i32.const 5)) (i32.const 101)) ;; 'e'
    (i32.store8 (i32.add (local.get $greeting_ptr) (i32.const 6)) (i32.const 108)) ;; 'l'       
    (i32.store8 (i32.add (local.get $greeting_ptr) (i32.const 7)) (i32.const 108)) ;; 'l'
    (i32.store8 (i32.add (local.get $greeting_ptr) (i32.const 8)) (i32.const 111)) ;; 'o'
    (i32.store8 (i32.add (local.get $greeting_ptr) (i32.const 9)) (i32.const 44)) ;; ','
    (i32.store8 (i32.add (local.get $greeting_ptr) (i32.const 10)) (i32.const 32)) ;; ' '

    ;; Copy the name into the greeting
    (memory.copy
      (i32.add (local.get $greeting_ptr) (i32.const 11)) ;; destination
      (local.get $name_ptr) ;; source
      (local.get $name_len)) ;; length

    ;; Return the pointer to the greeting
    (local.get $greeting_ptr)   
  )

  ;; Export the functions (NOTE: memory is also exported above)
  (export "greet" (func $greet))
  (export "alloc" (func $alloc)))

