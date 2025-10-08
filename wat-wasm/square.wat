(module
  ;; Make a square function that takes an i32 and returns its square
  (func $square (param $x i32) (result i32)
    ;; push x parameter onto stack
    local.get $x
    ;; push x parameter onto stack again
    local.get $x
    ;; multiply the two top values on the stack
    i32.mul)

  ;; Export the function
  (export "square" (func $square)))
