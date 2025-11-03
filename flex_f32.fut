import "human_flex"

module flex_f32 = {
    let run [m] [n] (ks: [m]i32) (shp: [m]i32) (II1: [n]i32) (A: [n]f32) : *[m]f32 =
        human_flex.rankSearchBatch 0f32 (<) (==) (ks: [m]i32) (shp: [m]i32) (II1: [n]i32) (A: [n]f32) 
}