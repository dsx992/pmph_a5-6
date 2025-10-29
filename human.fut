import "common"

let c = 10i64

module human = {
    def rankSearchBatch [m] [n] (ks: [m]i32) (shp: [m]i32) (II1: [n]i32) (A: [n]f32) : *[m]f32 =
        -- find initial flag
        let result = replicate m 0f32

        let (_,_,_,_,result) =
        -- loop (ks: [m]i32, shp: [m]i32, II1, A, result)
        loop (ks: *[m]i32, shp: *[m]i32, II1: *[]i32, A: *[]f32, result: *[m]f32)
            = (copy ks, copy shp, copy II1, copy A, result)
            while (length A > 0) do
            -- let flag = mkFlag (map ( \ _ -> false) A) true (map i64.i32 shp)
            -- let sgmlast = scan (+) 0 shp |> map (+ (-1))
            -- let ps = map ( \ i -> A[max i 0] ) sgmlast
            let offsets = scan (+) 0 shp
            let pivots = map2 (\offset len -> 
                if len > 0 then A[offset - 1] else 0f32
            ) offsets shp


            -- let pivots = map2 (\offset len ->
            --     if len <= 0 then 0f32
            --     else if len == 1 then A[offset - 1]
            --     else if len == 2 then A[offset - 2]
            --     else
            --         let start = offset - len
            --         let mid = start + len / 2
            --         let end = offset - 1
            --         let a = A[start]
            --         let b = A[mid]
            --         let c = A[end]
            --         in if a < b 
            --            then if b < c then b else if a < c then c else a
            --            else if a < c then a else if b < c then c else b
            -- ) offsets shp

            -- let lths = map2 ( \ a ii -> a < ps[ii] ) A II1
            -- let eqts = map2 ( \ a ii -> a == ps[ii]) A II1

            let lths = map2 (\a ii -> i32.bool (a < pivots[ii])) A II1
            let eqts = map2 (\a ii -> i32.bool (a == pivots[ii])) A II1

            -- let cntlths = sgmCount lths shp flag
            -- let cnteqts = sgmCount eqts shp flag

            let zeros = replicate m 0i32
            let (cntlths, cnteqts) =
                reduce_by_index 
                    (zip zeros zeros)
                    (\(l1,e1) (l2,e2) -> (l1+l2, e1+e2))
                    (0, 0)
                    (map i64.i32 II1)
                    (zip lths eqts)
                |> unzip


            -- let cntgths = map3 ( \ sh lt eq -> sh - lt - eq ) shp cntlths cnteqts


            -- let kinds =
            --     map4 ( \ k sh lth eqt ->
            --         if      sh == 0         then -1
            --         else if k <= lth        then 0
            --         else if k <= lth + eqt  then 1
            --                                 else 2
            --     ) ks shp cntlths cnteqts

            -- let shp' = 
            --     map3 ( \ kd lth gth ->  
            --         match kd
            --         case -1   -> 0
            --         case 0    -> lth
            --         case 1    -> 0
            --         case 2    -> gth
            --         case _    -> -1
            --     ) kinds cntlths cntgths

            -- let ks' =
            --     map4 ( \ kd k lth eqt ->
            --         match kd
            --         case -1   -> -1
            --         case 0    -> k
            --         case 1    -> -1
            --         case 2    -> k - lth - eqt
            --         case _    -> -1
            --     ) kinds ks cntlths cnteqts

            let (kinds, shp', ks') =
                map4 (\k sh lth eqt ->
                    if      sh == 0         then (-1, 0, k)
                    else if k <= lth        then (0, lth, k)
                    else if k <= lth + eqt  then (1, 0, -1)
                                            else (2, sh - lth - eqt, k - lth - eqt)
                ) ks shp cntlths cnteqts
                |> unzip3


            let result =
                map3 ( \ kd r p ->
                    if kd == 1  then p
                                else r
                ) kinds result pivots

            let elem_kinds = map (\ii -> kinds[ii]) II1
            let keep = 
                map3 (\kind lth eq ->
                    (kind == 0 && lth == 1) || 
                    (kind == 2 && lth == 0 && eq == 0)
                ) elem_kinds lths eqts
           
            -- let (A', II1', _, _) =
            --     zip4 A II1 lths eqts
            --     |> filter ( \ (_, ii, lth, eqt) ->
            --             if      kinds[ii] == -1   then false
            --             else if kinds[ii] == 0    then lth
            --             else if kinds[ii] == 1    then false
            --                                       else !(lth || eqt))
            -- unzip4

            let (A', II1') =
                zip A II1
                |> zip keep
                |> filter (.0)
                |> map (.1)
                |> unzip
            in (copy ks', shp', II1', copy A', result)
        in  result
}


