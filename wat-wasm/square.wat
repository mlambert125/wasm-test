(module
  (func $square (param $x i32) (result i32)
    local.get $x
    local.get $x
    i32.mul
  )
  (export "square" (func $square))
)
