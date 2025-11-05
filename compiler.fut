import "common"

def segFilter [m] [n] (A: [n](f32,i32)) (ps: [m]f32) (pred: f32 -> f32 -> bool): *[](f32,i32) =
    filter (\ (a, ii) -> pred a ps[ii] ) A

module compiler = {
    def rankSearchBatch [m] [n] (ks: [m]i32) (shp: [m]i32) (A: [n]f32) : *[m]f32 =
        let result = replicate m 0f32

        let flag =  mkFlag (map ( \ _ -> false) A) true (map i64.i32 shp)
        let II1  =  (scan (+) 0 (map (i32.bool) flag)) 
                        |> map (\ i -> i - 1)
        let (_,_,_,_,result) =
        loop (ks: [m]i32, shp: [m]i32, II1, A, result)
            = (copy ks, copy shp, copy II1, copy A, result)
        while (length A > 0) do
            -- the random pivots are just the last element in each subarray
            let sgmlast = scan (+) 0 shp |> map (+ (-1))
            let ps = map ( \ i -> A[max i 0] ) sgmlast

            let zipped = zip3 A II1 (map (\ ii -> ps[ii]) II1)
            -- use partition to filter A into three arrays
            let (A_lth_p, A_eqt_p, A_gth_p) = partition2 (\ (a,_ ,p ) -> a < p) (\ (a,_ ,p ) -> a == p) zipped
            
            -- shape of filtered A
            let lth_shp = hist (+) 0 m  (map (\ (_, i, _) -> i64.i32 i) A_lth_p 
                            :> [length A_lth_p]i64)
                            <| replicate (length A_lth_p) 1
            let eqt_shp = hist (+) 0 m (map (\ (_, i, _) -> i64.i32 i) A_eqt_p 
                            :> [length A_eqt_p]i64) 
                            <| replicate (length A_eqt_p) 1
            let gth_shp = hist (+) 0 m (map (\ (_, i, _) -> i64.i32 i) A_gth_p 
                            :> [length A_gth_p]i64)
                            <| replicate (length A_gth_p) 1 

            let kinds = 
                map4 ( \ k sh lth eqt ->
                    if      sh == 0         then -1
                    else if k <= lth        then 0
                    else if k <= lth + eqt  then 1
                                            else 2
                ) ks shp lth_shp eqt_shp

            let shp' =
                map3 ( \ kd lth gth ->  
                    match kd
                    case -1   -> 0
                    case 0    -> lth
                    case 1    -> 0
                    case 2    -> gth
                    case _    -> -1
                ) kinds lth_shp gth_shp

            let ks' =
                map4 ( \ kd k lth eqt ->
                    match kd
                    case -1   -> -1
                    case 0    -> k
                    case 1    -> -1
                    case 2    -> k - lth - eqt
                    case _    -> -1
                ) kinds ks lth_shp eqt_shp

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


entry compiler_f [m] [n] (ks: [m]i32) (shp: [m]i32) (II1: [n]i32) (A: [n]u32) : *[m]f32 = compiler.rankSearchBatch ks shp (map f32.u32 A)