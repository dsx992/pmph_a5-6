import "common"

let c = 10i64

module human = {
    def innerRankSearchBatch 't[m][n] 
        (lt : t -> t -> bool) 
        (eq : t -> t -> bool)
        (ne : t) 
        (ps : [m]t)
        (ks: [m]i32) 
        (shp: [m]i32) 
        (II1: *[n]i32) 
        (A: [n]t) 
        : *[m]t =

        let result = replicate m ne
        let (_,_,_,_,_,result) =
            loop (ps : [m]t, ks: [m]i32, shp: [m]i32, II1, A, result)
                = (copy ps, copy ks, copy shp, copy II1, copy A, result)
            while (length A > 0) do
                let II1_64 = map i64.i32 II1
            -- 2.
                let lths = map2 ( \ a ii -> lt a ps[ii]) A II1
                let eqts = map2 ( \ a ii -> eq a ps[ii]) A II1
                let histlth = hist (+) 0 m II1_64 (map i64.bool lths)
                let histeqt = hist (+) 0 m II1_64 (map i64.bool eqts)

            -- 3
                let (kinds, shp', ks') =
                    map4 ( \ k sh lth eqt ->      -- kind shp ks
                        if      sh == 0         then (-1, 0, k)
                        else if k <= lth        then (0, lth, k)
                        else if k <= lth + eqt  then (1, 0, -1)
                                                else (2, sh - lth - eqt, k - lth - eqt)
                    ) ks shp (map i32.i64 histlth) (map i32.i64 histeqt)
                    |> unzip3

            -- 4.
                let result =
                    map3 ( \ kd r p ->
                        if kd == 1  then p
                                    else r
                    ) kinds result (ps :> [m]t)
           
            -- 5.
                let (A', II1', _, _) =
                    zip4 A II1 lths eqts
                    |> filter ( \ (_, ii, lth, eqt) ->
                        if      kinds[ii] == -1   then false
                        else if kinds[ii] == 0    then lth
                        else if kinds[ii] == 1    then false
                                                  else !(lth || eqt))
                    |> unzip4
            -- 1. 
                -- finder pivot elementer (gennemsnit)
                let ps =
                        let shp_sc = scan (+) 0 shp
                        in map (\ sc -> A[max 0 (sc - 1)]) shp_sc
                in (ps, ks', shp', II1', A', result)
        in  result

    def rankSearchBatch 't[m][n] 
        (lt : t -> t -> bool) 
        (eq : t -> t -> bool)
        (ne : t)
        (_ : (k : i64) -> [n]t -> [n]i64 -> *[k]t)
        (ks: [m]i32) 
        (shp: [m]i32) 
        (II1: *[n]i32) 
        (A: [n]t) 
        : *[m]t
        =
        let ps = 
            let shp_sc = scan (+) 0 shp
            in map (\ sc -> A[max 0 (sc - 1)]) shp_sc
        in innerRankSearchBatch lt eq ne ps ks shp II1 A
}
