

def f [n] (A : [n]i32) =
    loop (A : ?[n].[n]i32) = A
    while (length A > 0) do
        -- let A' = #[trace] filter (!= A[0]) A
        let sz = 
            let B = scan (+) 0 A
            in B[B[1]] + 2 |> i64.i32
        let A' =  A ++ (replicate sz 1)
        in #[trace] A'
