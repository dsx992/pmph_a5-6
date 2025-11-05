import "../compiler"

-- ==
-- entry: compiler
-- input {  
--          [1, 1] 
--          [4, 4] 
--          [3f32, 5f32, 4f32, 2f32, 1f32, 2f32, 3f32, 4f32] }
-- output { [2.0f32, 1.0f32] }
-- input {  [1, 3, 2, 5, 1] 
--          [2, 4, 4, 5, 1] 
--          [ 1f32, 2f32,
--            4f32, 5f32, 0f32, 5f32,
--            -7f32, 2f32, -25f32, 19f32,
--            5f32, 4f32, 3f32, 2f32, 1f32,
--            420f32 ] }
-- output { [1f32, 5f32, -7f32, 5f32, 420f32] }

entry compiler = compiler.rankSearchBatch
