
def f [m][n] 
    (_: [m]i32) 
    (_: [m]i32) 
    (_: *[n]i32) 
    (_: [n]f32) 
    : i32 =
    1

-- ==
-- entry: test
-- compiled input @ blah
entry test = f


