import "human"
import "compiler"
-- ==
-- entry:  human 
-- compiled input @ test1.in
--
entry human = 
let avg [n] (k : i64) (A : [n]f32) (II1_i64 : [n]i64) : *[k]f32 = hist (+) 0f32 k II1_i64 A
in  human.rankSearchBatch (<) (==) 0f32 avg
-- ==
-- entry: compiler 
-- compiled input @ testCompiler1.in
--
entry compiler = compiler.rankSearchBatch
