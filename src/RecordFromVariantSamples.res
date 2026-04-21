open Comptime

type v0 =
  | Name(string)
  | Age(int)

type r0 = %comptime({
  let fieldNameFromConstructor = name =>
    switch name {
    | "Name" => "name"
    | "Age" => "age"
    | _ => failwith("makeRecordFromVariant only supports the sample constructors")
    }

  let makeRecordFromVariant = _witness =>
    switch reflect() {
    | Variant({constructors}) =>
      Record({
        fields: constructors->Array.map(constructor => {
          name: fieldNameFromConstructor(constructor.name),
          typ: switch constructor.payload {
          | Single(Int) => Optional(Int)
          | Single(desc) => desc
          | _ => failwith("makeRecordFromVariant only supports single-payload constructors")
          },
        }),
      })
    | _ => failwith("makeRecordFromVariant only supports variants")
    }

  makeRecordFromVariant(
    module(
      {
        type t = v0
      }
    ),
  )
})

let personR0: r0 = {name: "Ada"}
let personR1: r0 = {name: "Idris", age: 19}

Console.log(personR0)
