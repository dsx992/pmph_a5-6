import "lib/github.com/diku-dk/sorts/quick_sort"
import "common"

def cmp ((a, aii) : (f32, i32)) ((b, bii ): (f32, i32)) : bool =
    if aii == bii   then a <= b
                    else aii <= bii

module naive = {
  def rankSearchBatch [m] [n] (ks: [m]i32) (shp: [m]i32) (II1: *[n]i32) (A: [n]f32) : *[m]f32 =
      let sorted = #[trace] qsort cmp (zip A II1)
      let starts = exScan (+) 0 shp
      in  map2 ( \ k s -> sorted[k + s - 1].0 ) ks starts
}

entry main [m] [n] (ks: [m]i32) (shp: [m]i32) (A: [n]f32) : *[m]f32 = 
    let flag = mkFlag (map ( \ _ -> false) A) true (map i64.i32 shp)
    let II1  = scan (+) 0 (map (i32.bool) flag) |> map (\ i -> i-1)
    in naive.rankSearchBatch ks shp II1 A
