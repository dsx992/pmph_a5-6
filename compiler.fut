module compiler = {
    def rankSearchBatch [m] [n] (ks: [m]i32) (shp: [m]i32) (II1: *[n]i32) (A: [n]f32) : *[m]f32 =
        let result = replicate m 0f32
        let (_,_,_,_,result) =
        loop (ks: [m]i32, shp: [m]i32, II1, A, result)
          = (copy ks, copy shp, copy II1, copy A, result)
        while (length A > 0) do
            let flag = mkFlag (map ( \ _ -> false) A) true (map i64.i32 shp)
            -- find last element as pivot
            let shp_sc  = scan (+) 0 shp
            let ps  = map (\ x -> if (x == 0) then A[x] else A[x-1]) shp_sc

            -- find relations to pivots
            let (A_lth_ps, lth_II1) =
              zip A II1
              |> filter (\ (a, ii) -> a < p[ii])
              |> unzip 
            let (A_eqt_ps, eqt_II1) =
              zip A II1
              |> filter (\ (a, ii) -> a == p[ii])
              |> unzip 
            let (A_gth_ps, gth_II1) =
              zip A II1
              |> filter (\ (a, ii) -> a > p[ii])
              |> unzip 
            map 
    in result
}
