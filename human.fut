import "common"

module human = {
    def innerRankSearchBatch 't[m][n] 
        (lt : t -> t -> bool) 
        (eq : t -> t -> bool)
        (ne : t) 
        (ps : *[m]t)
        (ks: *[m]i32) 
        (shp: *[m]i32) 
        (II1: *[n]i32) 
        (A: *[n]t) 
        : *[m]t =

        let zlths = replicate m 0i32
        let zeqts = replicate m 0i32

        let result = replicate m ne
        let (_,_,_,_,_,result) =
            loop (ps : [m]t, ks: [m]i32, shp: [m]i32, II1, A, result)
                = (ps, ks, shp, II1, A, result)
            while (length A > 0) do
                let pss = map ( \ ii -> ps[ii]) II1

            -- 2.
                let (lths, eqts) =
                    map2 ( \ a ps -> (lt a ps, eq a ps)) A pss
                    |> unzip
                -- let lths = map2 ( \ a ii -> lt a ps[ii]) A II1
                -- let eqts = map2 ( \ a ii -> eq a ps[ii]) A II1
                let (histlth, histeqt) =
                    zip (map i32.bool lths) (map i32.bool eqts)
                    |> reduce_by_index
                        (zip (zlths :> [m]i32) (zeqts :> [m]i32))
                        ( \ (lt, eq) (lt', eq') -> (lt + lt', eq + eq'))
                        (0, 0)
                        (map i64.i32 II1)
                    |> unzip
                -- let histlth = hist (+) 0 m II1_64 (map i64.bool lths)
                -- let histeqt = hist (+) 0 m II1_64 (map i64.bool eqts)

            -- 3
                let (kinds, shp', ks') =
                    map4 ( \ k sh lth eqt ->      -- kind shp ks
                        if      sh == 0         then (-1, 0, k)
                        else if k <= lth        then (0, lth, k)
                        else if k <= lth + eqt  then (1, 0, -1)
                                                else (2, sh - lth - eqt, k - lth - eqt)
                    ) ks shp histlth histeqt
                    |> unzip3
                
                let kiinds =
                    -- let falses = map ( \ _ -> false) A -- getting right size for compiler
                    -- let zeros = map ( \ _ -> 0) A
                    -- let inds = exScan (+) 0 shp' |> map (i64.i32)
                    -- let flag = scatter falses inds (replicate m true)
                    -- let vals = scatter zeros inds kinds
                    -- in sgmScan (+) 0 flag vals
                    map ( \ ii -> kinds[ii]) II1

            -- 4.
                let result =
                    map3 ( \ kd r p ->
                        if kd == 1  then p
                                    else r
                    ) kinds result (ps :> [m]t)
           
            -- 5.
                let (A', II1', _, _, _) =
                    zip5 A II1 kiinds lths eqts
                    |> filter ( \ (_, _, kiind, lth, eqt) ->
                        if      kiind == -1   then false
                        else if kiind == 0    then lth
                        else if kiind == 1    then false
                                                  else !(lth || eqt))
                    |> unzip5
            -- 1. 
                -- finder pivot elementer (gennemsnit)
                let ps =
                    let shp_sc = scan (+) 0 shp'
                    in map (\ sc -> A[max 0 (sc - 1)]) shp_sc
                in (ps, ks', shp', II1', A', result)
        in  result

    def rankSearchBatch 't[m][n] 
        (lt : t -> t -> bool) 
        (eq : t -> t -> bool)
        (ne : t)
        (_ : (k : i64) -> [n]t -> [n]i64 -> *[k]t)
        (ks: *[m]i32) 
        (shp: *[m]i32) 
        (II1: *[n]i32) 
        (A: *[n]t) 
        : *[m]t
        =
        -- let ps = avg m A (map i64.i32 II1)
        let ps =
            let shp_sc = scan (+) 0 shp
            in map (\ sc -> A[max 0 (sc - 1)]) shp_sc
        in innerRankSearchBatch lt eq ne ps ks shp II1 A
}
