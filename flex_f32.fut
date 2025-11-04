import "human_generic"

module generic_f32 = {
    let run [m] [n] (ks: [m]i32) (shp: [m]i32) (II1: [n]i32) (A: [n]f32) : *[m]f32 =
        human_generic.rankSearchBatch 0f32 (<) (==) (ks: [m]i32) (shp: [m]i32) (II1: [n]i32) (A: [n]f32) 
}