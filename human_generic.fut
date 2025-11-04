import "common"

module human_generic = {

    def median3 't (lt: t -> t -> bool) (eq: t -> t -> bool) (a: t) (b: t) (c: t) : t =
        if lt a b || eq a b 
        then if lt b c || eq b c then b       
                else if lt a c || eq a c  then c  
                else a                 
        else if lt a c || eq a c then a       
                else if lt b c || eq b c then c 
                else b 
    -- We use any type t
    -- we must pass a neutral element and the function for lees than and equal
    def rankSearchBatch [m] [n] 't (ne: t) (lt: t -> t -> bool) (eq: t -> t -> bool) (add: t -> t -> t) (div: t -> f32 -> t) (ks: [m]i32) (shp: [m]i32 ) (II1: [n]i32) (A: [n]t) : *[m]t =
        let result = replicate m ne
        -- map reduce to find sum of each sub array
        let flag' = mkFlag (map ( \ _ -> false) A) true (map i64.i32 shp)
        let flag  = flag' :> [n]bool
        let sc    = sgmScan (add) ne flag A
        let indsp = scan (+) 0 shp
        let sum   = map2 (\ sh ip1 -> if (sh==0) then ne else sc[ip1-1]) shp indsp

        -- pivots are average values to cut away half
        let ps    = map2 (\ sh su -> div su sh) (map (f32.i32) shp) sum

        -- find new values

        let (cntlths, cnteqts) =
                    hist (\(a1, a2) (b1, b2) -> (a1 + b1, a2 + b2)) (0i32, 0i32) m (map i64.i32 II1)
                        (map2 (\lth eqt -> (i32.bool lth, i32.bool eqt)) 
                        (map2 ( \ a ii -> lt a ps[ii] ) A II1)
                        (map2 ( \ a ii -> eq a ps[ii]) A II1))
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
                        if      kd == -1  then 0
                        else if kd == 0   then lth
                        else if kd == 1   then 0
                        else                   sh - lth - eq
                    ) kinds cntlths cnteqts shp

        let ks' =
                    map4 ( \ kd k lth eqt ->
                        if      kd == -1  then -1
                        else if kd == 0   then k
                        else if kd == 1   then -1
                        else                   k - lth - eqt
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
                    else if kinds[ii] == 0    then lt a ps[ii]
                    else if kinds[ii] == 1    then false
                                                else !(lt a ps[ii]) && !(eq a ps[ii]))
            |> unzip

        -- loop while length of A is greater than
        let (_,_,_,_, result) =
            loop (ks: [m]i32, shp: [m]i32, II1, A, result)
                = (copy ks', copy shp', copy II1', copy A', copy result)
            while (length A > 0) do
                -- let sgmlast = scan (+) 0 shp |> map (+ (-1))
                -- let ps = map ( \ i -> A[max i 0] ) sgmlast
                -- let ps = map ( \ i -> if i >= 0 then A[i] else 0) sgmlast

                let offsets = exscan (+) 0 shp
                let ps = map2 (\off sz -> 
                    if sz == 0 then ne
                    else if sz == 1 then A[off]
                    else if sz == 2 then A[off]
                    else 
                        let first = A[off]
                        let mid = A[off + sz / 2]
                        let last = A[off + sz - 1]
                        in median3 (lt) (eq) first mid last
                ) offsets shp


            let (cntlths, cnteqts) =
                        hist (\(a1, a2) (b1, b2) -> (a1 + b1, a2 + b2)) (0i32, 0i32) m (map i64.i32 II1)
                            (map2 (\lth eqt -> (i32.bool lth, i32.bool eqt)) 
                            (map2 ( \ a ii -> lt a ps[ii] ) A II1)
                            (map2 ( \ a ii -> eq a ps[ii]) A II1))
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
                        if      kd == -1  then 0
                        else if kd == 0   then lth
                        else if kd == 1   then 0
                        else                   sh - lth - eq
                    ) kinds cntlths cnteqts shp


                let ks' =
                    map4 ( \ kd k lth eqt ->
                        if      kd == -1  then -1
                        else if kd == 0   then k
                        else if kd == 1   then -1
                        else                   k - lth - eqt
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
                            else if kinds[ii] == 0    then lt a ps[ii]
                            else if kinds[ii] == 1    then false
                                                        else !(lt a ps[ii]) && !(eq a ps[ii]))
                    |> unzip
                in (ks', shp', II1', A', result)
            in  result
    }
