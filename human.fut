-- Generic segmented scan (generic in the binary operator and in the element
-- type, t, of the segmented array).
-- (fra aflevering 1)
def sgmScan [n] 't
            (op: t -> t -> t)
            (ne: t)
            (flags: [n]bool)
            (vals: [n]t)
            : [n]t =
  scan (\(f1, v1) (f2, v2) -> (f1 || f2, if f2 then v2 else op v1 v2))
       (false, ne)
       (zip flags vals)
  |> unzip
  |> (.1)


-- ved ikke hvorfor jeg selv skrev den, findes den ikke også i docs?
def exScan [n] 't (op : t -> t -> t) (ne : t) (A : [n]t) : [n]t =
    scan op ne A
    |> rotate (-1)
    |> zip (iota n)
    |> map (\ (i, a) -> if (i == 0) then ne else a)


def mkFlag [n] [m] (zeros : *[n]i64) (shp : [m]i64) : [n]i64 =
    let inds = exScan (+) 0 shp
    let ones = map (\ _ -> 1) shp
    in  scatter zeros inds ones

def rankSearchBatch [m] [n] (ks: [m]i32) (shp: [m]i32) (II1: *[n]i32) (A: [n]f32) : *[m]f32 =
    let result = replicate m 0f32
    let (_,_,_,_,result) =
        loop (ks: [m]i32, shp: [m]i32, II1, A, result)
        while (length A > 0) do
        -- 1. compute the pivot for each subproblem, e.g., by choosing the
        --    last element. This is a small parallel operation of size m.

            -- finder pivot elementer
            let ps = map (\i ->
                if (i == 0) then A[i]
                else A[i - 1]) shp

        -- 2. for each subproblem compute the number of elements less than
        --    or equal to the pivot. This is a large-parallel operation of
        --    size n. Hint: use a histogram or reduce_by_index construct.

            let flag = mkFlag (replicate m 0i64) (map i64.i32 shp)

            -- (til næste 3 let bindings)
            -- finder A_*_p fra første implementering i pdf'en.
            -- basically segmented scan på prædikat og summer over dem.
            -- De har alle tre stort set samme kode, så måske det skulle flyttes
            -- ud i en funktion
            let (plths, plthos) =
                -- ones er det array på længde A hvor prædikatet er opfyldt
                -- (altså en af comparisons)
                let ones = map3 (\ a i ps -> 
                        a < ps[i]) A II1 (replicate m ps)
                let scn = sgmScan (+) 0 ones flag |> map (i32.i64)
                let cnt = map(\i ->
                        if (i == 0) then -1
                        else scn[i - 1]) shp
                in (cnt, ones)

            let (peqs, peqos) = 
                let ones = map3 (\ a i ps -> 
                        a == ps[i]) A II1 (replicate m ps)
                let scn = sgmScan (+) 0 ones flag |> map (i32.i64)
                let cnt = map(\i ->
                        if (i == 0) then -1
                        else scn[i - 1]) shp
                in (cnt, ones)

            let (pgths, pgthos) =
                let ones = map3 ( \ a i ps -> 
                        a > ps[i]) A II1 (replicate m ps)
                let scn = sgmScan (+) 0 ones flag |> map (i32.i64)
                let cnt = map( \i ->
                        if (i == 0) then -1
                        else scn[i - 1]) shp
                in (cnt, ones)

        -- 3. Use a small-parallel operation of size m to compute:
        --    3.1 kinds → the kind of each subproblem, e.g.,
        --         (a) -1 means that this subproblem was already solved
        --         (b) 0  means that it should recurse in “< pivot” dir
        --         (c) 1  means that the base case was reached
        --         (d) 2  means that it should recurse in “> pivot” dir

            let kinds = 
                map3 ( \ plth peq k -> 
                    if      plth == -1 || peq == -1 then -1
                    else if k <= plth               then 0
                    else if k <= (plth + peq)       then 1
                                                    else 2) plths peqs ks
        --    3.2 shp’ → the new shape after this iteration, e.g., if
        --               we just discovered kinds==1 for some subproblem
        --               then we should set the corresponding element of
        --               shp’ to zero.

            let shp' = 
                map3 ( \ kd plth pgth -> 
                    match kd
                    case -1 -> 0        -- er det rigtigt?
                    case 0  -> plth
                    case 1  -> 0
                    case 2  -> pgth
                    case _  -> -1       -- der er sket en fejl
                ) kinds plths pgths

        --    3.3 ks’  → the new value of k for each subproblem
        --               (the inactive subproblems may use -1 or similar)

            -- Bruger igen første pseudo løsning til at finde ud af værdierne 
            -- til k.
            let ks' =
                map4 ( \ k kd plth peq ->
                    match kd
                    case -1 -> k        -- bør de her cases ændres?
                    case 0  -> k
                    case 1  -> k
                    case 2  -> k - plth - peq
                    case _  -> -1       -- der er sket en fejl
                ) ks kinds plths peqs


        -- 4. write to result the solutions of the subproblems that have
        --    just finished (have kinds 1)
            let result =
                map3 (\ r kd p -> 
                    if kd == 1  then p
                                else r) result kinds ps

       
        -- 5. filter the A and II1 arrays to contain only the elements of
        --  interest of the subproblems that are still active.

            -- samler alle ones. Mængden af 1 taller bør være ens med den nye
            -- total size af A
            let ones = map3 ( \ lt eq gt -> lt || eq || gt) plthos peqos pgthos
            
            let A' =
                zip A ones
                |> filter ( \ ( _, o) -> o)
                |> map ( \ (a, _) -> a)

            let II1' = 
                let size = reduce (+) 0 ks' |> i64.i32
                let inds = exScan (+) 0 ks' |> map i64.i32
                let flag = mkFlag (replicate size 0) (map i64.i32 ks') |> map bool.i64
                let vals = scatter (replicate size 0) inds ks'
                in  sgmScan (+) 0 flag vals
            -- map2 (\ i n -> replicate n i) (indices shp') shp

            in (ks', shp', II1', A', result)
    in  result
