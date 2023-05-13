entry add [n] (xs: [n]u8) (ys: [n]u8): [n]u8 =
  map2 (+) xs ys
