import "common"
import "heuristik"

module human = {
    def rankSearchBatch [m] [n] (ks: [m]i32) (shp: [m]i32) (II1: *[n]i32) (A: [n]f32) : *[m]f32 =
        let result = replicate m 0f32
        let (_,_,_,_,result) =
            loop (ks: [m]i32, shp: [m]i32, II1, A, result)
                = (copy ks, copy shp, copy II1, copy A, result)
            while (length A > 0) do
                let m' = length ks
                let II1_64 = map i64.i32 II1
            -- 1. 
                -- finder pivot elementer
                -- perchance option type?
                -- heuristik: if length A > x then p = avg / 2
                -- update: det er altid ass, og hvis x er sat for lavt så stalller den bare totalt
                let sgmlast = scan (+) 0 shp |> map (+ (-1))
                let ps = #[trace]
                    if #[trace] length A > x then
                        hist (+) 0f32 m' II1_64 A
                        |> map ( \ h -> h / (length A |> f32.i64)) 
                    else
                        map ( \ i -> A[max i 0] ) sgmlast

            -- 2.
                let lths = map2 ( \ a ii -> a < ps[ii]) A II1
                let eqts = map2 ( \ a ii -> a == ps[ii]) A II1
                let histlth = hist (+) 0 m' II1_64 (map i64.bool lths) :> [m]i64
                let histeqt = hist (+) 0 m' II1_64 (map i64.bool eqts) :> [m]i64

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
                    ) kinds result (ps :> [m]f32)
           
            -- 5.
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
