import "lib/github.com/diku-dk/cpprandom/random"

let rankSearch 't (k : i64) (A: []t) : t =
    let p = random_element A
