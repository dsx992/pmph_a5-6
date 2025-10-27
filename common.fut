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
