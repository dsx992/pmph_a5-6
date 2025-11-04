import "common"

module human= {
    def rankSearchBatch [m] [n] (ks: [m]i32) (shp: [m]i32) (II1: [n]i32) (A: [n]f32): *[m]f32 =
        let result = replicate m 0f32

        let (_,_,_,_,result) =
        loop (ks: [m]i32, shp: [m]i32, II1, A, result)
            = (copy ks, copy shp, copy II1, copy A, result)
        while (length A > 0) do
            let shp_sc = exscan (+) 0 shp
            let ps = map2 ( \ k sh -> if (sh + k - 1) >= 0 then A[(sh + k - 1)] else -1 ) ks shp_sc

            let (cntlths, cnteqts) =
                hist (\(a1, a2) (b1, b2) -> (a1 + b1, a2 + b2)) 
                    (0i32, 0i32) m (map i64.i32 II1)
                    (map2 (\lth eqt -> (i32.bool lth, i32.bool eqt)) 
                    (map2 (\ a ii -> a < ps[ii] ) A II1)
                    (map2 (\ a ii -> a == ps[ii]) A II1))
                |> unzip

            let kinds =
                map4 ( \ k sh lth eqt ->
                    if      sh == 0         then -1
                    else if k <= lth        then 0
                    else if k <= lth + eqt  then 1
                                            else 2
                ) ks shp cntlths cnteqts

            let shp' = 
                map4 ( \ kd lth eq sh->  
                    match kd
                    case -1   -> 0
                    case 0    -> lth
                    case 1    -> 0
                    case 2    -> sh - lth - eq
                    case _    -> -1
                ) kinds cntlths cnteqts shp

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
           
            let (A', II1') =
                zip A II1
                |> filter ( \ (a, ii) ->
                        if      kinds[ii] == -1   then false
                        else if kinds[ii] == 0    then a < ps[ii]
                        else if kinds[ii] == 1    then false
                                                  else a > ps[ii])
                |> unzip
            in (ks', shp', II1', A', result)
        in  result
}
