import "common"

module compiler = {
    def rankSearchBatch [m] [n] (ks: [m]i32) (shp: [m]i32) (A: [n]f32) : *[m]f32 =
        -- find initial flag
        let result = replicate m 0f32
        let flag = mkFlag (map ( \ _ -> false) A) true (map i64.i32 shp)

        -- find II1 by scanning over the flag
        let II1  = scan (+) 0 (map (i32.bool) flag) |> map (\ i -> i-1)

        let (_,_,_,_,result) =
        loop (ks: [m]i32, shp: [m]i32, II1, A, result)
            = (copy ks, copy shp, II1, copy A, result)
        while (length A > 0) do
            let flag = mkFlag (map ( \ _ -> false) A) true (map i64.i32 shp)
            let sgmlast = scan (+) 0 shp |> map (+ (-1))
            let ps = map ( \ i -> A[max i 0] ) sgmlast

            let lths = map2 ( \ a ii -> a < ps[ii] ) A II1
            let eqts = map2 ( \ a ii -> a == ps[ii]) A II1

            let cntlths = sgmCount lths shp flag
            let cnteqts = sgmCount eqts shp flag
            let cntgths = map3 ( \ sh lt eq -> sh - lt - eq ) shp cntlths cnteqts

            let kinds =
                map4 ( \ k sh lth eqt ->
                    if      sh == 0         then -1
                    else if k <= lth        then 0
                    else if k <= lth + eqt  then 1
                                            else 2
                ) ks shp cntlths cnteqts

            let shp' = 
                map3 ( \ kd lth gth ->  
                    match kd
                    case -1   -> 0
                    case 0    -> lth
                    case 1    -> 0
                    case 2    -> gth
                    case _    -> -1
                ) kinds cntlths cntgths

            let ks' =
                map4 ( \ kd k lth eqt ->
                    match kd
                    case -1   -> -1
                    case 0    -> k
                    case 1    -> -1
                    case 2    -> k - lth - eqt
                    case _    -> -1
                ) kinds ks cntlths cnteqts

            let result =
                map3 ( \ kd r p ->
                    if kd == 1  then p
                                else r
                ) kinds result ps
           
            let (A', II1', _, _) =
                zip4 A II1 lths eqts
                |> filter ( \ (_, ii, lth, eqt) ->
                        if      kinds[ii] == -1   then false
                        else if kinds[ii] == 0    then lth
                        else if kinds[ii] == 1    then false
                                                  else !(lth || eqt))
                |> unzip4
            in (ks', shp', II1', A', result)
        in  result
}
