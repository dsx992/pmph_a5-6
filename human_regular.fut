import "common"

module human_regular = {
    def median3 (a: f32) (b: f32) (c: f32) : f32 =
            if a <= b 
            then if b <= c then b       
                 else if a <= c then c  
                 else a                 
            else if a <= c then a       
                 else if b <= c then c 
                 else b 

    def rankSearchBatch [m] [n] (ks: [m]i32) (shp: [m]i32) (II1: [n]i32) (A: [n]f32): *[m]f32 =
        let result = replicate m 0f32
        -- map reduce to find sum of each sub array
        -- let flag' = mkFlag (map ( \ _ -> false) A) true (map i64.i32 shp)
        -- let flag  = flag' :> [n]bool
        -- let sc    = sgmScan (+) 0 flag A
        -- let indsp = scan (+) 0 shp
        -- let sum   = map2 (\ sh ip1 -> if (sh==0) then 0 else sc[ip1-1]) shp indsp

        -- -- pivots are average values to cut away half
        -- let ps    = map2 (\ sh su -> su / sh) (map (f32.i32) shp) sum

        -- -- find new values
        -- let lths = map2 ( \ a ii -> a < ps[ii] ) A II1
        -- let eqts = map2 ( \ a ii -> a == ps[ii]) A II1

        -- let (cntlths, cnteqts) =
        --             hist (\(a1, a2) (b1, b2) -> (a1 + b1, a2 + b2)) (0i32, 0i32) m (map i64.i32 II1)
        --                 (map2 (\lth eqt -> (i32.bool lth, i32.bool eqt)) lths eqts)
        --             |> unzip

        -- let kinds =
        --     map4 ( \ k sh lth eqt ->
        --         if      sh == 0         then -1
        --         else if k <= lth        then 0
        --         else if k <= lth + eqt  then 1
        --                                 else 2
        --     ) ks shp cntlths cnteqts

        -- let shp' = 
        --     map4 ( \ kd lth eq sh->  
        --         match kd
        --         case -1   -> 0
        --         case 0    -> lth
        --         case 1    -> 0
        --         case 2    -> sh - lth - eq
        --         case _    -> -1
        --     ) kinds cntlths cnteqts shp

        -- let ks' =
        --     map4 ( \ kd k lth eqt ->
        --         match kd
        --         case -1   -> -1
        --         case 0    -> k
        --         case 1    -> -1
        --         case 2    -> k - lth - eqt
        --         case _    -> -1
        --     ) kinds ks cntlths cnteqts

        -- let result =
        --     map3 ( \ kd r p ->
        --         if kd == 1  then p
        --                     else r
        --     ) kinds result ps
        
        -- let (A', II1', _, _) =
        --     zip4 A II1 lths eqts
        --     |> filter ( \ (_, ii, lth, eqt) ->
        --             if      kinds[ii] == -1   then false
        --             else if kinds[ii] == 0    then lth
        --             else if kinds[ii] == 1    then false
        --                                         else !(lth || eqt))
        --     |> unzip4

        -- loop while length of A is greater than
        let (_,_,_,_, result) =
            loop (ks: [m]i32, shp: [m]i32, II1, A, result)
                = (copy ks, copy shp, copy II1, copy A, copy result)
            while (length A > 0) do
                -- let sgmlast = scan (+) 0 shp |> map (+ (-1))
                -- let ps = map ( \ i -> A[max i 0] ) sgmlast
                -- let ps = map ( \ i -> if i >= 0 then A[i] else 0) sgmlast

                -- let offsets = scan (+) 0 shp
                let offsets = exscan (+) 0 shp
                let ps = map2 (\off sz -> 
                    if sz == 0 then 0f32
                    else if sz == 1 then A[off]
                    else if sz == 2 then A[off]
                    else 
                        let first = A[off]
                        let mid = A[off + sz / 2]
                        let last = A[off + sz - 1]
                        in median3 first mid last
                ) offsets shp

                let lths = map2 ( \ a ii -> a < ps[ii] ) A II1
                let eqts = map2 ( \ a ii -> a == ps[ii]) A II1

                let (cntlths, cnteqts) =
                            hist (\(a1, a2) (b1, b2) -> (a1 + b1, a2 + b2)) (0i32, 0i32) m (map i64.i32 II1)
                                (map2 (\lth eqt -> (i32.bool lth, i32.bool eqt)) lths eqts)
                            |> unzip

                      
                let kinds =
                    map4 ( \ k sh lth eqt ->
                        if      sh == 0         then -1
                        else if k <= lth        then 0
                        else if k <= lth + eqt  then 1
                                                else 2
                    ) ks shp cntlths cnteqts

                -- let shp' = 
                --     map4 ( \ kd lth eq sh->  
                --         match kd
                --         case -1   -> 0
                --         case 0    -> lth
                --         case 1    -> 0
                --         case 2    -> sh - lth - eq
                --         case _    -> -1
                --     ) kinds cntlths cnteqts shp

                let shp' = 
                    map4 ( \ kd lth eq sh->  
                        if      kd == -1  then 0
                        else if kd == 0   then lth
                        else if kd == 1   then 0
                        else                   sh - lth - eq
                    ) kinds cntlths cnteqts shp


                -- let ks' =
                --     map4 ( \ kd k lth eqt ->
                --         match kd
                --         case -1   -> -1
                --         case 0    -> k
                --         case 1    -> -1
                --         case 2    -> k - lth - eqt
                --         case _    -> -1
                --     ) kinds ks cntlths cnteqts
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

                -- let keep_flags = 
                --     map2 (\ii (lth, eqt) ->
                --         let kd = kinds[ii]
                --         in if      kd == -1  then false
                --            else if kd == 0   then lth
                --            else if kd == 1   then false
                --            else                   !(lth || eqt)
                --     ) II1 (zip lths eqts)
                
                -- let (A', II1') = 
                --     zip A II1
                --     |> zip keep_flags  
                --     |> filter (.0)     
                --     |> unzip 
                
                -- let (A', II1', _, _) =
                --     zip4 A II1 lths eqts
                --     |> filter ( \ (_, ii, lth, eqt) ->
                --             if      kinds[ii] == -1   then false
                --             else if kinds[ii] == 0    then lth
                --             else if kinds[ii] == 1    then false
                --                                         else !(lth || eqt))
                --     |> unzip4

                let (A', II1') = 
                    map3 (\a ii (lth, eqt) ->
                        let kd = kinds[ii]
                        let keep = if      kd == -1  then false
                                   else if kd == 0   then lth
                                   else if kd == 1   then false
                                   else                   !(lth || eqt)
                        in (keep, a, ii)
                    ) A II1 (zip lths eqts)
                    |> filter (.0)             
                    |> map (\(_, a, ii) -> (a, ii))  
                    |> unzip 
            
                in (ks', shp', II1', A', result)
            in  result
    
}
