import "human"
import "human_regular"
import "compiler"
-- ==
-- entry:  human human_regular
-- compiled input @ test1.in
--
entry human = human.rankSearchBatch 
entry human_regular = human_regular.rankSearchBatch
-- ==
-- entry: compiler 
-- compiled input @ testCompiler1.in
--
entry compiler = compiler.rankSearchBatch
