let rankSearchBatch (ks: [m]i32) (shp: [m]i32) (II1: *[n]i32) (A: [n]f32): *[m]f32 =
        let result = replicate m 0f32
        -- Find flag
        let shp_sc  = scan (+) 0 ks
        let rep0    = replicate num_elms false
        let flag    = scatter rep0 shp_exc_sc (replicate num_rows true)
        let (_,_,_,_,result) =
            loop (ks: [m]i32, shp: [m]i32, II1, A, result)
            while (length A > 0) do
                -- Step 1
                let pivots = map (\ x -> A[x-1]) flag

                -- Step 2
    in result


let main [m] [n] (ks: [m]i32) (shp: [m]i32) (A: [n]f32): [m]f32 =
    -- We find II1
    let shp_sc  = scan (+) 0 ks
    let rep0    = replicate num_elms false
    let flag    = scatter rep0 shp_exc_sc[:-1] (replicate num_rows true)
    let II1     = scan (+) 0 flag 
    let res     = (rankSearchBatch ks shp II1 A)
    in res