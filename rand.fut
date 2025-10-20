import "lib/github.com/diku-dk/cpprandom/random"

let main () =
    let A = [1,2,3]
    let rng = engine.rng_from_seed [1111]
    let (rng, _) = dist.rand d rng
    let rngs = engine.split_rng n rng
    let (_, xs) = unzip (map (dist.rand d) rngs)
    in xs