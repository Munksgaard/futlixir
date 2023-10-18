entry add [n] (xs: [n]u8) (ys: [n]u8): [n]u8 =
  map2 (+) xs ys

entry add_i64 [n] (xs: [n]i64) (ys: [n]i64): [n]i64 =
  map2 (+) xs ys

entry addi [n] (xs: [n]i32) (i: i32): [n]i32 =
  map (+ i) xs

type point = {x: f64, y: f64}

entry addp [n] (points: [n]point) (i: f64): []point =
  map (\{x, y} -> {x = x + i, y = y + i}) points

entry addr [n] (point: {x: [n]point, y: [n]point}) (i: f64): []point =
  []

entry to_points [n] (xs: [n]f64) (ys: [n]f64): [n]point =
  map2 (\x y -> {x = x, y = y}) xs ys

entry to_xs [n] (points: [n]point): [n]f64 =
  map (.x) points

def dotprod [n] (xs: [n]f64) (ys: [n]f64): f64 =
  map2 (+) xs ys
  |> reduce (+) 0

entry matmul [n][m][p] (a: [n][m]f64) (b: [m][p]f64): [n][p]f64 =
  map (\a_row -> map (\b_col -> dotprod a_row b_col) (transpose b)) a

entry matplus [n][m] (a: [n][m]u8) (b: [n][m]u8): [n][m]u8 =
  map2 (map2 (+)) a b
