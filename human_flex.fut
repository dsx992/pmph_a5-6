import "common"

module human_flex = {
    -- We use any type t
    -- we must pass a neutral element and the function for lees than and equal
    def rankSearchBatch [m] [n] 't (ne: t) (lt: t -> t -> bool) (eq: t -> t -> bool)  (ks: [m]i32) (shp: [m]i32 ) (II1: [n]i32) (A: [n]t) : *[m]t =
        let result = replicate m ne

        let (_,_,_,_,result) =
        loop (ks: [m]i32, shp: [m]i32, II1, A, result)
            = (copy ks, copy shp, copy II1, copy A, result)
        while (length A > 0) do
            let sgmlast = scan (+) 0 shp |> map (+ (-1))
            let ps = map ( \ i -> A[max i 0] ) sgmlast

            let lths = map2 ( \ a ii -> lt a ps[ii]) A II1
            let eqts = map2 ( \ a ii -> eq a ps[ii]) A II1


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
