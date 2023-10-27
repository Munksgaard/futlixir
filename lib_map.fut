-- ==
-- entry: matmul
-- input { [[1.0f64, 2.0f64, 3.0f64], [4.0f64, 5.0f64, 6.0f64], [7.0f64, 8.0f64, 9.0f64]] [[1.0f64, 2.0f64, 3.0f64], [4.0f64, 5.0f64, 6.0f64], [7.0f64, 8.0f64, 9.0f64]] }
-- output { [[30.0f64, 36.0f64, 42.0f64], [66.0f64, 81.0f64, 96.0f64], [102.0f64, 126.0f64, 150.0f64]] }


entry add [n] (xs: [n]u8) (ys: [n]u8): [n]u8 =
  map2 (+) xs ys

entry add_i64 [n] (xs: [n]i64) (ys: [n]i64): [n]i64 =
  map2 (+) xs ys

entry addi [n] (xs: [n]i32) (i: i32): [n]i32 =
  map (+ i) xs

type point = {x: f64, y: f64}

entry addp [n] (points: [n]point) (i: f64): []point =
  map (\{x, y} -> {x = x + i, y = y + i}) points

type foo[n] = ([n]u8, [n]u8)

entry add_foo [n] (input: foo[n]): foo[n] =
  (map2 (+) input.0 input.1, map2 (-) input.0 input.1)

entry addr [n] (point: {x: [n]point, y: [n]point}) (i: f64): []point =
  []

entry to_points [n] (xs: [n]f64) (ys: [n]f64): [n]point =
  map2 (\x y -> {x = x, y = y}) xs ys

entry to_xs [n] (points: [n]point): [n]f64 =
  map (.x) points

def dotprod [n] (xs: [n]f64) (ys: [n]f64): f64 =
  map2 (*) xs ys
  |> reduce (+) 0

entry matmul [n][m][p] (a: [n][m]f64) (b: [m][p]f64): [n][p]f64 =
  map (\a_row -> map (\b_col -> dotprod a_row b_col) (transpose b)) a

entry matplus [n][m] (a: [n][m]u8) (b: [n][m]u8): [n][m]u8 =
  map2 (map2 (+)) a b
