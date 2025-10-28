import "common"

def segFilter (A: [](f32, f32)) (pred: f32 -> f32 -> bool): *[](f32,f32) =
    filter (\ (a, ii) -> pred a ii ) A

module compiler = {
    def rankSearchBatch [m] [n] (ks: [m]i32) (shp: [m]i32) (A: [n]f32) : *[m]f32 =
        let result = replicate m 0f32

        let (_,_,_,result) =
        loop (ks: [m]i32, shp: [m]i32, A, result)
            = (copy ks, copy shp, copy A, result)
        while (length A > 0) do
            let flag = mkFlag (map ( \ _ -> false) A) true (map i64.i32 shp)
            let II1  = (scan (+) 0 (map (i32.bool) flag)) 
                        |> map (\ i -> i - 1)
                        
            -- the random pivots are just the last element in each subarray
            let sgmlast = scan (+) 0 shp |> map (+ (-1))
            let ps = map ( \ i -> A[max i 0] ) sgmlast

            let zipped = zip A (map (\ i -> ps[i]) II1)

            -- filter A
            let A_lth_p = segFilter zipped (<)
            let A_eqt_p = segFilter zipped (==)
            let A_gth_p = segFilter zipped (>)
            
            -- shape of filtered A
            let lth_shp = hist (+) 0 m (map (\ (_, i) -> i64.f32 i) A_lth_p 
                            :> [length A_lth_p]i64)
                            <| replicate (length A_lth_p) 1
            let eqt_shp = hist (+) 0 m (map (\ (_, i) -> i64.f32 i) A_eqt_p 
                            :> [length A_eqt_p]i64) 
                            <| replicate (length A_eqt_p) 1
            let gth_shp = hist (+) 0 m (map (\ (_, i) -> i64.f32 i) A_gth_p 
                            :> [length A_gth_p]i64)
                            <| replicate (length A_gth_p) 1 

            let kinds =
                map4 ( \ k sh lth eqt ->
                    if      sh == 0         then -1
                    else if k <= lth        then 0
                    else if k <= lth + eqt  then 1
                                            else 2
                ) ks shp lth_shp eqt_shp

            let shp' = 
                map3 ( \ kd lth gth ->  
                    match kd
                    case -1   -> 0
                    case 0    -> lth
                    case 1    -> 0
                    case 2    -> gth
                    case _    -> -1
                ) kinds lth_shp gth_shp

            let ks' =
                map4 ( \ kd k lth eqt ->
                    match kd
                    case -1   -> -1
                    case 0    -> k
                    case 1    -> -1
                    case 2    -> k - lth - eqt
                    case _    -> -1
                ) kinds ks lth_shp eqt_shp

            let result =
                map3 ( \ kd r p ->
                    if kd == 1  then p
                                else r
                ) kinds result ps
           
            let (A', _) =
                zip A II1
                |> filter ( \ (a, ii) ->
                        if      kinds[ii] == -1   then false
                        else if kinds[ii] == 0    then a < ps[ii]
                        else if kinds[ii] == 1    then false
                                                  else a > ps[ii])
                |> unzip

            in (ks', shp', A', result)
        in  result
    -- def rankSearchBatch [m] [n] (ks: [m]i32) (shp: [m]i32) (A: [n]f32) : *[m]f32 =
    --     -- find initial flag
    --     let result = replicate m 0f32
    --     let flag = mkFlag (map ( \ _ -> false) A) true (map i64.i32 shp)

    --     -- find II1 by scanning over the flag
    --     let II1  = scan (+) 0 (map (i32.bool) flag) |> map (\ i -> i-1)

    --     let (_,_,_,_,result) =
    --     loop (ks: [m]i32, shp: [m]i32, II1, A, result)
    --         = (copy ks, copy shp, II1, copy A, result)
    --     while (length A > 0) do
    --         let flag = mkFlag (map ( \ _ -> false) A) true (map i64.i32 shp)
    --         let sgmlast = scan (+) 0 shp |> map (+ (-1))
    --         let ps = map ( \ i -> A[max i 0] ) sgmlast

    --         let lths = map2 ( \ a ii -> a < ps[ii] ) A II1
    --         let eqts = map2 ( \ a ii -> a == ps[ii]) A II1

    --         let cntlths = sgmCount lths shp flag
    --         let cnteqts = sgmCount eqts shp flag
    --         let cntgths = map3 ( \ sh lt eq -> sh - lt - eq ) shp cntlths cnteqts

    --         let kinds =
    --             map4 ( \ k sh lth eqt ->
    --                 if      sh == 0         then -1
    --                 else if k <= lth        then 0
    --                 else if k <= lth + eqt  then 1
    --                                         else 2
    --             ) ks shp cntlths cnteqts

    --         let shp' = 
    --             map3 ( \ kd lth gth ->  
    --                 match kd
    --                 case -1   -> 0
    --                 case 0    -> lth
    --                 case 1    -> 0
    --                 case 2    -> gth
    --                 case _    -> -1
    --             ) kinds cntlths cntgths

    --         let ks' =
    --             map4 ( \ kd k lth eqt ->
    --                 match kd
    --                 case -1   -> -1
    --                 case 0    -> k
    --                 case 1    -> -1
    --                 case 2    -> k - lth - eqt
    --                 case _    -> -1
    --             ) kinds ks cntlths cnteqts

    --         let result =
    --             map3 ( \ kd r p ->
    --                 if kd == 1  then p
    --                             else r
    --             ) kinds result ps
           
    --         let (A', II1', _, _) =
    --             zip4 A II1 lths eqts
    --             |> filter ( \ (_, ii, lth, eqt) ->
    --                     if      kinds[ii] == -1   then false
    --                     else if kinds[ii] == 0    then lth
    --                     else if kinds[ii] == 1    then false
    --                                               else !(lth || eqt))
    --             |> unzip4
    --         in (ks', shp', II1', A', result)
    --     in  result
}
