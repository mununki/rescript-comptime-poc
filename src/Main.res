open Comptime

type user = {
  name: string,
  age: int,
  active: bool,
}

type animal = {
  species: string,
  age: int,
  wild: bool,
}

let makeJsonEncoder:
  type t. unit => t => JSON.t =
  () => {
    switch reflect() {
    | Record({fields}) =>
      let encodeField = (field, value) =>
        switch field.typ {
        | String => JSON.String(field.get(value))
        | Int => JSON.Number(Int.toFloat(field.get(value)))
        | Bool => JSON.Boolean(field.get(value))
        | _ => failwith("makeJsonEncoder only supports string, int, and bool fields")
        }

      (value: t) => {
        let builder = fields->Array.reduce(Dict.make(), (builder, field) => {
          let nextBuilder = Dict.copy(builder)
          Dict.set(nextBuilder, field.name, encodeField(field, value))
          nextBuilder
        })

        JSON.Object(builder)
      }
    | _ => failwith("makeJsonEncoder only supports record types")
    }
  }

let makeRecordCopy:
  type t. unit => t => t =
  () => {
    switch reflect() {
    | Record({fields}) =>
      (value: t) =>
        fields->Array.reduce(Dict.make(), (builder, field) => {
          let nextBuilder = Dict.copy(builder)
          Dict.set(nextBuilder, field.name, field.get(value))
          nextBuilder
        })
    | _ => failwith("makeRecordCopy only supports record types")
    }
  }

let makeJsonDecoder:
  type t. unit => JSON.t => option<t> =
  () => {
    switch reflect() {
    | Record({fields}) =>
      let decodeField = (field, obj) =>
        switch field.typ {
        | String =>
          switch Dict.get(obj, field.name) {
          | Some(JSON.String(value)) => Some(value)
          | _ => None
          }
        | Int =>
          switch Dict.get(obj, field.name) {
          | Some(JSON.Number(value)) => Some(Float.toInt(value))
          | _ => None
          }
        | Bool =>
          switch Dict.get(obj, field.name) {
          | Some(JSON.Boolean(value)) => Some(value)
          | _ => None
          }
        | _ => failwith("makeJsonDecoder only supports string, int, and bool fields")
        }

      let finish = (_obj, builder) => Some(builder)

      let addDecodedField = (next, field) =>
        (obj, builder) =>
          switch decodeField(field, obj) {
          | Some(value) =>
            let nextBuilder = Dict.copy(builder)
            Dict.set(nextBuilder, field.name, value)
            next(obj, nextBuilder)
          | None => None
          }

      let decodeObject = fields->Array.reduceRight(finish, addDecodedField)

      (json: JSON.t) =>
        switch json {
        | JSON.Object(obj) => decodeObject(obj, Dict.make())
        | _ => None
        }
    | _ => failwith("makeJsonDecoder only supports record types")
    }
  }

let encodeUser: user => JSON.t = %comptime(makeJsonEncoder())

let decodeUser: JSON.t => option<user> = %comptime(makeJsonDecoder())

let copyUser: user => user = %comptime(makeRecordCopy())

let encodeAnimal: animal => JSON.t = %comptime(makeJsonEncoder())

let decodeAnimal: JSON.t => option<animal> = %comptime(makeJsonDecoder())

let copyAnimal: animal => animal = %comptime(makeRecordCopy())

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

/*
Uncomment this binding to prove that %comptime runs during compilation.
`pnpm build` will fail before JS is emitted.

let broken: int = %comptime(failwith("ran during compilation"))
*/

let ada = {name: "Ada", age: 42, active: true}
let encodedAda = encodeUser(ada)
let decodedAda = decodeUser(encodedAda)
let copiedAda = copyUser(ada)

let fox = {species: "Fox", age: 5, wild: true}
let encodedFox = encodeAnimal(fox)
let decodedFox = decodeAnimal(encodedFox)
let copiedFox = copyAnimal(fox)

Console.log(three)
Console.log(greeting)
Console.log(encodedAda)
Console.log(decodedAda)
Console.log(copiedAda)
Console.log(encodedFox)
Console.log(decodedFox)
Console.log(copiedFox)
