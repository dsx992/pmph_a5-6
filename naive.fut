
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

def rankSearchBatch (ks: [m]i32) (shp: [m]i32) (II1: *[n]i32) (A: [n]f32) : *[m]f32 =
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

            -- finder mængden af less than or equal ved sgmscan og så tag
            -- sidste indeks (per segment)
            let lths =
                let scn =
                    map3 (\ a i ps -> 
                        a <= ps[i]
                        |> i32.bool) A II1 (replicate m ps)
                    |> sgmScan (+) 0
                in  map(\i ->
                        if (i == 0) then A[i]
                        else A[i - 1]) shp

        -- 3. Use a small-parallel operation of size m to compute:
        --    3.1 kinds → the kind of each subproblem, e.g.,
        --         (a) -1 means that this subproblem was already solved
        --         (b) 0  means that it should recurse in “< pivot” dir
        --         (c) 1  means that the base case was reached
        --         (d) 2  means that it should recurse in “> pivot” dir
        --    3.2 shp’ → the new shape after this iteration, e.g., if
        --               we just discovered kinds==1 for some subproblem
        --               then we should set the corresponding element of
        --               shp’ to zero.
        --    3.3 ks’  → the new value of k for each subproblem
        --               (the inactive subproblems may use -1 or similar)
       
        -- 4. write to result the solutions of the subproblems that have
        --    just finished (have kinds 1)
        -- 5. filter the A and II1 arrays to contain only the elements of
        --  interest of the subproblems that are still active.
    in  result
