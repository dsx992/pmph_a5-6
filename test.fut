import "naive"
import "human"

-- ==
-- entry: human naive
-- input {  [1, 1] 
--          [4, 4] 
--          [0, 0, 0, 0, 1, 1, 1, 1] 
--          [3f32, 5f32, 4f32, 2f32, 1f32, 2f32, 3f32, 4f32] }
-- output { [2.0f32, 1.0f32] }
entry human = human.rankSearchBatch
entry naive = naive.rankSearchBatch

-- rankSearchBatch [1, 1] [4, 4] [0, 0, 0, 0, 1, 1, 1, 1] [3, 5, 4, 2, 1, 2, 3, 4]
