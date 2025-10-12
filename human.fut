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
            -- 1. 
                let flag = mkFlag (map ( \ _ -> false) A) true (map i64.i32 shp)

                let sgmlast = scan (+) 0 shp |> map (+ (-1))

                -- finder pivot elementer
                -- perchance option type?
                let ps = map ( \ i -> A[max i 0] ) sgmlast

            -- 2.
                let lths = map2 ( \ a ii -> a < ps[ii] ) A II1
                let eqts = map2 ( \ a ii -> a == ps[ii]) A II1
                let gths = map2 ( \ a ii -> a > ps[ii]) A II1
                let cntlths = sgmCount lths shp flag
                let cnteqts = sgmCount eqts shp flag
                let cntgths = sgmCount gths shp flag

            -- 3.
                let kinds =
                    map4 ( \ k sh lth eqt ->
                        if      sh == 0         then -1
                        else if k <= lth        then 0
                        else if k <= lth + eqt  then 1
                                                else 2
                    ) ks shp cntlths cnteqts

            -- 3.2
                let shp' = 
                    map3 ( \ kd lth gth ->  
                        match kd
                        case -1   -> 0
                        case 0    -> lth
                        case 1    -> 0
                        case 2    -> gth
                        case _    -> -1
                    ) kinds cntlths cntgths

            -- 3.3
                let ks' =
                    map4 ( \ kd k lth eqt ->
                        match kd
                        case -1   -> -1
                        case 0    -> k
                        case 1    -> -1
                        case 2    -> k - lth - eqt
                        case _    -> -1
                    ) kinds ks cntlths cnteqts

            -- 4.
                let result =
                    map3 ( \ kd r p ->
                        if kd == 1  then p
                                    else r
                    ) kinds result ps
           
            -- 5.
                let (A', II1', _, _) =
                    zip4 A II1 lths gths
                    |> filter ( \ (_, ii, lth, gth) ->
                        match kinds[ii]
                        case -1 -> false
                        case 0  -> lth
                        case 1  -> false
                        case 2  -> gth
                        case _  -> false)
                    |> unzip4
                in (ks', shp', II1', A', result)
        in  result
}
