entry add [n] (xs: [n]u8) (ys: [n]u8): [n]u8 =
  map2 (+) xs ys

entry add_i64 [n] (xs: [n]i64) (ys: [n]i64): [n]i64 =
  map2 (+) xs ys

entry addi [n] (xs: [n]i32) (i: i32): [n]i32 =
  map (+ i) xs
