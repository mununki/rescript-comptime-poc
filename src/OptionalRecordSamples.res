open Comptime

type r0 = {
  name: string,
  age: int,
}

type optionalValueR0 = %comptime({
  let makeOptionRecord = _witness =>
    switch reflect() {
    | Record({fields}) =>
      Record({
        fields: fields->Array.map(field => {
          name: field.name,
          typ: Option(field.typ),
        }),
      })
    | _ => failwith("makeOptionRecord only supports records")
    }

  makeOptionRecord(
    module(
      {
        type t = r0
      }
    ),
  )
})

type optionalFieldR0 = %comptime({
  let makeOptionalFieldRecord = _witness =>
    switch reflect() {
    | Record({fields}) =>
      Record({
        fields: fields->Array.map(field => {
          name: field.name,
          typ: Optional(field.typ),
        }),
      })
    | _ => failwith("makeOptionalFieldRecord only supports records")
    }

  makeOptionalFieldRecord(
    module(
      {
        type t = r0
      }
    ),
  )
})

let emptyOptionalValueR0: optionalValueR0 = {name: None, age: None}
let fullOptionalValueR0: optionalValueR0 = {name: Some("Ada"), age: Some(42)}

let emptyOptionalFieldR0: optionalFieldR0 = {}
let fullOptionalFieldR0: optionalFieldR0 = {name: "Ada", age: 42}

Console.log(emptyOptionalValueR0)
Console.log(fullOptionalValueR0)
Console.log(emptyOptionalFieldR0)
Console.log(fullOptionalFieldR0)
