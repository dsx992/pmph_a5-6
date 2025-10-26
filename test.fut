import "human"

-- ==
-- entry: humanf32
-- input {  [1, 1] 
--          [4, 4] 
--          [0, 0, 0, 0, 1, 1, 1, 1] 
--          [3f32, 5f32, 4f32, 2f32, 1f32, 2f32, 3f32, 4f32] }
-- output { [2.0f32, 1.0f32] }
-- input {  [1, 3, 2, 5, 1] 
--          [2, 4, 4, 5, 1] 
--          [0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4] 
--          [ 1f32, 2f32,
--            4f32, 5f32, 0f32, 5f32,
--            -7f32, 2f32, -25f32, 19f32,
--            5f32, 4f32, 3f32, 2f32, 1f32,
--            420f32 ] }
-- output { [1f32, 5f32, -7f32, 5f32, 420f32] }
entry humanf32 = human.rankSearchBatch (<) (==) 0f32

-- ==
-- entry: humani32
-- input {  [1, 1] 
--          [4, 4] 
--          [0, 0, 0, 0, 1, 1, 1, 1] 
--          [3i32, 5i32, 4i32, 2i32, 1i32, 2i32, 3i32, 4i32] }
-- output { [2i32, 1i32] }
-- input {  [1, 3, 2, 5, 1] 
--          [2, 4, 4, 5, 1] 
--          [0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4] 
--          [ 1i32, 2i32,
--            4i32, 5i32, 0i32, 5i32,
--            -7i32, 2i32, -25i32, 19i32,
--            5i32, 4i32, 3i32, 2i32, 1i32,
--            420i32 ] }
-- output { [1i32, 5i32, -7i32, 5i32, 420i32] }
entry humani32 = human.rankSearchBatch (<) (==) 0i32

-- entry naive = naive.rankSearchBatch
-- entry compiler
