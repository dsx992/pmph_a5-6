-- ved ikke hvorfor jeg selv skrev den, findes den ikke også i docs?
def exScan [n] 't (op : t -> t -> t) (ne : t) (A : [n]t) : [n]t =
    scan op ne A
    |> rotate (-1)
    |> zip (iota n)
    |> map (\ (i, a) -> if (i == 0) then ne else a)


def mkFlag 't [n] [m] (zeros : *[n]t) (one : t) (shp : [m]i64) : *[n]t =
    let inds = exScan (+) 0 shp
    let ones = map (\ _ -> one) shp
    in  scatter zeros inds ones


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

def max (a : i32) (b : i32) =
    if a > b 
    then a
    else b

def sgmCount [n] [m] (bs : [n]bool) (shp : [m]i32) (flag : [n] bool) : [m]i32 =
    let is = map i32.bool bs
    let scn = sgmScan (+) 0 flag is
    let sgmlast = scan (+) 0 shp |> map (+ (-1))
    in  map ( \ i -> scn[max i 0] ) sgmlast

def rankSearchBatch [m] [n] (ks: [m]i32) (shp: [m]i32) (II1: *[n]i32) (A: [n]f32) : *[m]f32 =
    let result = replicate m 0f32
    let (_,_,_,_,result) =
        loop (ks: [m]i32, shp: [m]i32, II1, A, result)
            = (copy ks, copy shp, copy II1, copy A, result)
        while (length A > 0) do
        -- 1. compute the pivot for each subproblem, e.g., by choosing the
        --    last element. This is a small parallel operation of size m.
        
            -- bør ikke være behov for et flag array når II1 eksisterer, tror..
            let flag = #[trace] mkFlag (map ( \ _ -> false) A) true (map i64.i32 shp)

            let sgmlast = scan (+) 0 shp |> map (+ (-1))

            -- finder pivot elementer
            -- muligvis problem når shp[x] = 0 -> i = -1
            -- perchance option type?
            let ps = map ( \ i -> A[max i 0] ) sgmlast

        -- 2. for each subproblem compute the number of elements less than
        --    or equal to the pivot. This is a large-parallel operation of
        --    size n. Hint: use a histogram or reduce_by_index construct.

            let lths = map2 ( \ a ii -> a < ps[ii] ) A II1
            let eqts = map2 ( \ a ii -> a == ps[ii]) A II1
            let gths = map2 ( \ a ii -> a > ps[ii]) A II1
            let cntlths = sgmCount lths shp flag
            let cnteqts = sgmCount eqts shp flag
            let cntgths = sgmCount gths shp flag

        -- 3. Use a small-parallel operation of size m to compute:
        --    3.1 kinds → the kind of each subproblem, e.g.,
        --         (a) -1 means that this subproblem was already solved
        --         (b) 0  means that it should recurse in “< pivot” dir
        --         (c) 1  means that the base case was reached
        --         (d) 2  means that it should recurse in “> pivot” dir

            let kinds =
                map4 ( \ k sh lth eqt ->
                    if      sh == 0         then -1
                    else if k <= lth        then 0
                    else if k <= lth + eqt  then 1
                                            else 2
                ) ks shp cntlths cnteqts

        --    3.2 shp’ → the new shape after this iteration, e.g., if
        --               we just discovered kinds==1 for some subproblem
        --               then we should set the corresponding element of
        --               shp’ to zero.

            let shp' = 
                map3 ( \ kd lth gth ->  
                    match kd
                    case -1   -> 0
                    case 0    -> lth
                    case 1    -> 0
                    case 2    -> gth
                    case _    -> -1
                ) kinds cntlths cntgths

        --    3.3 ks’  → the new value of k for each subproblem
        --               (the inactive subproblems may use -1 or similar)
            let ks' =
                map4 ( \ kd k lth eqt ->
                    match kd
                    case -1   -> -1
                    case 0    -> k
                    case 1    -> -1
                    case 2    -> k - lth - eqt
                    case _    -> -1
                ) kinds ks cntlths cnteqts

        -- 4. write to result the solutions of the subproblems that have
        --    just finished (have kinds 1)

            let result =
                map3 ( \ kd r p ->
                    if kd == 1  then p
                                else r
                ) kinds result ps
       
        -- 5. filter the A and II1 arrays to contain only the elements of
        --  interest of the subproblems that are still active.
            let (A', II1', _, _) =
                let filt = zip4 A II1 lths gths
                    |> filter ( \ (_, ii, lth, gth) ->
                        match kinds[ii]
                            case -1 -> false
                            case 0  -> lth
                            case 1  -> false
                            case 2  -> gth
                            case _  -> false)
                in unzip4 filt

            in (ks', shp', II1', A', result)
    in  result
