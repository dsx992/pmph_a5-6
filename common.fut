def exscan f ne xs =
  map2 (\i x -> if i == 0 then ne else x)
       (indices xs)
       (rotate (-1) (scan f ne xs))


def mkFlag 't [n] [m] (zeros : *[n]t) (one : t) (shp : [m]i64) : *[n]t =
    let inds = exscan (+) 0 shp
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