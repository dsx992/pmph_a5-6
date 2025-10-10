let sgmScan [n] 't
            (op: t -> t -> t)
            (ne: t)
            (flags: [n]bool)
            (vals: [n]t)
            : [n]t =
  scan (\(f1, v1) (f2, v2) -> (f1 || f2, if f2 then v2 else op v1 v2))
       (false, ne)
       (zip flags vals)
  |> unzip
  |> (.1)

def rankSearchBatch [m][n]
                    (ks: [m]i32) 
                    (shp: [m]i32) 
                    (II1: *[n]i32) 
                    (A: [n]f32)
                    : *[m]f32 =
    let result = replicate m 0f32
    -- Find flag
    -- let rep0    = replicate m false
    -- let flag    = scatter rep0 shp_sc (replicate m true)
    let (_,_,_,_,result) =
        loop (ks: [m]i32, shp: [m]i32, II1, A, result)
        while (length A > 0) do
            -- 1. compute the pivot for each subproblem, e.g., by choosing the
            --    last element. This is a small parallel operation of size m.
            let shp_sc  = scan (+) 0 shp
            let pivots  = map (\ x -> if (x == 0) then A[x] else A[x-1]) shp_sc

            -- 2. for each subproblem compute the number of elements less than
            --    or equal to the pivot. This is a large-parallel operation of
            --    size n. Hint: use a histogram or reduce_by_index construct.
            let zipped          = map2 (\ i x -> (pivots[i], x)) II1 A
            let A_lth_zipped    = reduce_by_index 
                                    (replicate n (0,0)) 
                                    (\ (_, acc) (p, x) -> (0, if x <= p then acc + 1 else acc))
                                    (0,0) 
                                    (map i64.i32 II1) 
                                    zipped 
            let A_lth           = map (\ (_, x) -> x ) A_lth_zipped

            -- 3. Use a small-parallel operation of size m to compute:
            --    3.1 kinds → the kind of each subproblem, e.g.,
            --         (a) -1 means that this subproblem was already solved
            --         (b) 0  means that it should recurse in “< pivot” dir
            --         (c) 1  means that the base case was reached
            --         (d) 2  means that it should recurse in “> pivot” dir
            -- let rep0    = replicate n 0
            -- let flag    = scatter rep0 (map i64.i32 shp_sc) (replicate m 1)
            
    in result
