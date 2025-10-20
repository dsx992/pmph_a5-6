import "common"

def sgmCount [n] [m] (bs : [n]bool) (shp : [m]i32) (flag : [n] bool) : [m]i32 =
    let is = map i32.bool bs
    let scn = sgmScan (+) 0 flag is
    let sgmlast = scan (+) 0 shp |> map (+ (-1))
    in  map ( \ i -> scn[max i 0] ) sgmlast

module human = {
    def rankSearchBatch [m] [n] (ks: [m]i32) (shp: [m]i32) (II1: *[n]i32) (A: [n]f32) : *[m]f32 =
        let result = replicate m 0f32
        let (_,_,_,_,result) =
            loop (ks: [m]i32, shp: [m]i32, II1, A, result)
                = (copy ks, copy shp, copy II1, copy A, result)
            while (length A > 0) do
                -- let m = length ks
            -- 1. 
                -- let shp_sc  = #[trace] scan (+) 0 (#[trace] shp)
                -- let ps  = map (\ x -> if (x == 0) then A[x] else A[x-1]) shp_sc
            let sgmLast = #[trace] scan (+) 0 (#[trace] shp) |> map (+ (-1))
            let ps = map (\ i -> A[max i 0]) sgmLast
            -- 2.

                let lth_cnt =
                    map2 ( \ a ii -> a < ps[ii] |> i32.bool) A II1
                    |> hist (+) 0 m (map i64.i32 II1) 
                let eqt_cnt =
                    map2 ( \ a ii -> a == ps[ii] |> i32.bool) A II1
                    |> hist (+) 0 m (map i64.i32 II1) 

            -- 3.
                -- let kinds =
                --     map4 ( \ k sh lth eqt ->
                --         if      sh == 0         then -1
                --         else if k <= lth        then 0
                --         else if k <= lth + eqt  then 1
                --                                 else 2
                --     ) ks shp cntlths cnteqts
                let kinds = map4 (\ k sh lth eqt -> 
                            if sh == 0              then -1
                            else if k <= lth        then 0
                            else if k <= lth + eqt  then 1
                            else 2
                            ) ks shp lth_cnt eqt_cnt
            -- 3.2
                -- let shp' = 
                --     map3 ( \ kd lth gth ->  
                --         match kd
                --         case -1   -> 0
                --         case 0    -> lth
                --         case 1    -> 0
                --         case 2    -> gth
                --         case _    -> -1
                --     ) kinds cntlths cntgths

                let shp' = 
                    map4 ( \ kd lth eqt sh ->  
                        match kd
                        case -1   -> 0
                        case 0    -> lth
                        case 1    -> 0
                        case 2    -> sh - lth - eqt
                        case _    -> -1
                    ) kinds lth_cnt eqt_cnt shp

            -- 3.3
                let ks' =
                    map4 ( \ kd k lth eq ->
                        match kd
                        case -1   -> -1
                        case 0    -> k
                        case 1    -> -1
                        case 2    -> k - lth - eq
                        case _    -> -1
                    ) kinds ks lth_cnt eqt_cnt

            -- 4.
                let result =
                    map3 ( \ kd r p ->
                        if kd == 1  then p
                                    else r
                    ) kinds result ps
           
            -- 5.
                let zipped     = map2 (\ i x -> (ps[i], x)) II1 A
                let (A', II1') =
                    zip2 zipped II1 
                    |> filter ( \ ((p,a), ii) ->
                        match kinds[ii]
                        case -1 -> false
                        case 0  -> a < p
                        case 1  -> false
                        case 2  -> a > p
                        case _  -> false)
                    |> map (\ ((_, a),ii) -> (a,ii))
                    |> unzip
                in (ks', shp', II1', A', result)
        in  result
}

-- def rankSearchBatch [m][n]
--                     (ks: [m]i32) 
--                     (shp: [m]i32) 
--                     (II1: *[n]i32) 
--                     (A: [n]f32)
--                     : *[m]f32 =
--     let result = replicate m 0f32
--     -- Find flag
--     -- let rep0    = replicate m false
--     -- let flag    = scatter rep0 shp_sc (replicate m true)
--     let (_,_,_,_,result) =
--         loop (ks: [m]i32, shp: [m]i32, II1, A, result)
--         while (length A > 0) do
--             -- 1. compute the pivot for each subproblem, e.g., by choosing the
--             --    last element. This is a small parallel operation of size m.
--             let shp_sc  = scan (+) 0 shp
--             let pivots  = map (\ x -> if (x == 0) then A[x] else A[x-1]) shp_sc

--             -- 2. for each subproblem compute the number of elements less than
--             --    or equal to the pivot. This is a large-parallel operation of
--             --    size n. Hint: use a histogram or reduce_by_index construct.
--             let zipped          = map2 (\ i x -> (pivots[i], x)) II1 A
--             let A_lth_zipped    = reduce_by_index 
--                                     (replicate n (0,0)) 
--                                     (\ (_, acc) (p, x) -> (0, if x <= p then acc + 1 else acc))
--                                     (0,0) 
--                                     (map i64.i32 II1) 
--                                     zipped 
--             let A_lth           = map (\ (_, x) -> x ) A_lth_zipped

--             -- 3. Use a small-parallel operation of size m to compute:
--             --    3.1 kinds → the kind of each subproblem, e.g.,
--             --         (a) -1 means that this subproblem was already solved
--             --         (b) 0  means that it should recurse in “< pivot” dir
--             --         (c) 1  means that the base case was reached
--             --         (d) 2  means that it should recurse in “> pivot” dir
--             -- let rep0    = replicate n 0
--             -- let flag    = scatter rep0 (map i64.i32 shp_sc) (replicate m 1)
            
--     in result
