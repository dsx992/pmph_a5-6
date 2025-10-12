def f [n] (A : [n]i32) =
    loop (A : ?[n].[n]i32, sz : i64) = (A, 0)
    while (length A > 0) do
        let _ = map (+ (i32.i64 n)) A

        let sz = 
            let B = scan (+) 0 A
            in B[n - 1] |> i64.i32

        let A' = (replicate sz 1)
        in #[trace] (A', sz)

def rank [n] (A : [n]i32) =
    loop A = A
    while length A > 0 do
        let A = A ++ [1]
        in A
