(module
  ;; Define our one and only memory with an initial size of 1 page (64KiB)
  (memory (export "memory") 1)

  ;; Say "Hello, $name" where $name is at memory address $addr
  ;; Caller should place the name length (4 bytes) and name bytes starting at address 500
  ;; Returns the greeting starting at address 0
  (func $greet
    (local $name_len i32)
    (local $greeting_len i32)   

    ;; Load the length of the name (first 4 bytes at 500)
    (local.set $name_len (i32.load (i32.const 500)))

    (local.set $greeting_len (i32.add (local.get $name_len) (i32.const 7))) 

    ;; Store the length of the greeting at the start
    (i32.store (i32.const 0) (local.get $greeting_len))

    ;; Store "Hello, " at the start of the greeting
    (i32.store8 (i32.const 4) (i32.const 72)) ;; 'H'
    (i32.store8 (i32.const 5) (i32.const 101)) ;; 'e'
    (i32.store8 (i32.const 6) (i32.const 108)) ;; 'l'       
    (i32.store8 (i32.const 7) (i32.const 108)) ;; 'l'
    (i32.store8 (i32.const 8) (i32.const 111)) ;; 'o'
    (i32.store8 (i32.const 9) (i32.const 44)) ;; ','
    (i32.store8 (i32.const 10) (i32.const 32)) ;; ' '

    ;; Copy the name into the greeting
    (memory.copy
      (i32.const 11) ;; destination
      (i32.const 504) ;; source
      (local.get $name_len)) ;; length
  )

  ;; Export the functions (NOTE: memory is also exported above)
  (export "greet" (func $greet)))

