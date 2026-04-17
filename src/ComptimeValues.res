open Comptime

let three: int = %comptime(
  if true {
    1 + 2
  } else {
    failwith("unreachable int branch")
  }
)

let greeting: string = %comptime(
  switch "x" {
  | "x" => "comp" ++ "time"
  | _ => failwith("unreachable string branch")
  }
)

Console.log(three)
Console.log(greeting)

/*
Uncomment this binding to prove that %comptime runs during compilation.
`pnpm build` will fail before JS is emitted.

let broken: int = %comptime(failwith("ran during compilation"))
*/
