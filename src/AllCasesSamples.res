open Comptime

type color =
  | Red
  | Green
  | Blue

let makeAllCases:
  type t. unit => array<t> =
  () =>
    switch reflect() {
    | Variant({constructors}) =>
      constructors->Array.map(constructor =>
        switch constructor.payload {
        | NoPayload => constructor.make()
        | _ => failwith("makeAllCases only supports no-payload variants")
        }
      )
    | _ => failwith("makeAllCases only supports variants")
    }

let allColors: array<color> = %comptime(makeAllCases())

Console.log(allColors)
