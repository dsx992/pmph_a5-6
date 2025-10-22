import "naive"
import "human"

-- entry mk_input (n:i64) =
--    let pattern = [0f32,1f32]
--    let bloat   = replicate 4 10f32
--    let ks      = replicate n 2i32
--    let shp     = replicate n 10i32
--    let II1     = (map (\ i -> replicate 10 (i32.i64 i)) (iota n)) |> flatten
--    let A       = (map (\ i -> replicate n i) (bloat ++ pattern ++ bloat)) |> flatten
--    in  (ks, shp, II1, A)
-- ==
-- entry: naive human
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
entry naive = naive.rankSearchBatch
entry human = human.rankSearchBatch
