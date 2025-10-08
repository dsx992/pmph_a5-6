def rankSearchBatch (ks: [m]i32) (shp: [m]i32) (II1: *[n]i32) (A:
    [n]f32) : *[m]f32 =
        let result = replicate m 0f32
        let (_,_,_,_,result) =
            loop (ks: [m]i32, shp: [m]i32, II1, A, result)
            while (length A > 0) do
                -- 1. compute the pivot for each subproblem, e.g., by choosing the last element. 
                    -- This is a small parallel operation of size m.
                -- 2. for each subproblem compute the number of elements less than or equal to the pivot.
                    -- This is a large-parallel operation of size n.
                    -- Hint: use a histogram or reduce_by_index construct.
                -- 3. Use a small-parallel operation of size m to compute:
                -- 3.1 kinds → the kind of each subproblem, e.g.,
                    -- (a) -1 means that this subproblem was already solved
                    -- (b) 0 means that it should recurse in “< pivot” dir
                    -- (c) 1 means that the base case was reached
                    -- (d) 2 means that it should recurse in “> pivot” dir
                -- 3.2 shp’ → the new shape after this iteration, e.g., if
                    -- we just discovered kinds==1 for some subproblem
                    -- then we should set the corresponding element of
                    -- shp’ to zero.
                -- 3.3 ks’ → the new value of k for each subproblem
                    -- (the inactive subproblems may use -1 or similar)
                -- 4. write to result the solutions of the subproblems that have
                    -- just finished (have kinds 1)
                -- 5. filter the A and II1 arrays to contain only the elements of
                    -- interest of the subproblems that are still active.
    in result