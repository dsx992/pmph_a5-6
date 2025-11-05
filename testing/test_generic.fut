import "../human_generic"
-- ==
-- entry: human_genericf32
-- input {  
--          [1, 1] 
--          [4, 4] 
--          [0, 0, 0, 0, 1, 1, 1, 1] 
--          [3f32, 5f32, 4f32, 2f32, 1f32, 2f32, 3f32, 4f32] }
-- output { [2.0f32, 1.0f32] }

entry human_genericf32 = human_generic.rankSearchBatch 0f32 (<) (==) (+) (/)
-- ==
-- entry: human_genericf64
-- input {  
--          [1, 1] 
--          [4, 4] 
--          [0, 0, 0, 0, 1, 1, 1, 1] 
--          [3f64, 5f64, 4f64, 2f64, 1f64, 2f64, 3f64, 4f64] }
-- output { [2.0f64, 1.0f64] }

entry human_genericf64 = human_generic.rankSearchBatch 0f64 (<) (==) (+) (\ a b -> f64.f32 (f32.f64 a / b))
-- ==
-- entry: human_generici32
-- input {  
--          [1, 1] 
--          [4, 4] 
--          [0, 0, 0, 0, 1, 1, 1, 1] 
--          [3i32, 5i32, 4i32, 2i32, 1i32, 2i32, 3i32, 4i32] }
-- output { [2i32, 1i32] }

entry human_generici32 = human_generic.rankSearchBatch 0i32 (<) (==) (+) (\ a b -> i32.f32 (f32.i32 a / b))
 