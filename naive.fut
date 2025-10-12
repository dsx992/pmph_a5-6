import "lib/github.com/diku-dk/sorts/quick_sort"

def exScan [n] 't (op : t -> t -> t) (ne : t) (A : [n]t) : [n]t =
    scan op ne A
    |> rotate (-1)
    |> zip (iota n)
    |> map (\ (i, a) -> if (i == 0) then ne else a)

def cmp ((a, aii) : (f32, i32)) ((b, bii ): (f32, i32)) : bool =
    if aii == bii   then a <= b
                    else aii <= bii

def rankSearchBatch [m] [n] (ks: [m]i32) (shp: [m]i32) (II1: *[n]i32) (A: [n]f32) : *[m]f32 =
    let sorted = #[trace] qsort cmp (zip A II1)
    let starts = exScan (+) 0 shp
    in  map2 ( \ k s -> sorted[k + s - 1].0 ) ks starts
