open Comptime

type user = {
  name: string,
  age: int,
  active: bool,
}

let makeJsonEncoder:
  type t. unit => Code.t<t => JSON.t> =
  () => {
    let desc = reflect()

    switch desc {
    | Record({fields}) =>
      let rows = Array.map(fields, field =>
        switch field.typ {
        | String => (field.name, %quote(JSON.String(%splice(field.get(%quote(value))))))
        | Int => (field.name, %quote(JSON.Number(Int.toFloat(%splice(field.get(%quote(value)))))))
        | Bool => (field.name, %quote(JSON.Boolean(%splice(field.get(%quote(value))))))
        | _ => compileError("makeJsonEncoder only supports string, int, and bool fields")
        }
      )

      %quote((value: t) => JSON.Object(%splice(Code.dict(rows))))
    | _ => compileError("makeJsonEncoder only supports record types")
    }
  }

let makeJsonDecoder:
  type t. unit => Code.t<JSON.t => option<t>> =
  () => {
    let desc = reflect()

    switch desc {
    | Record({name, fields}) =>
      let decodedFields = Array.map(fields, field => (
        field.name,
        switch field.typ {
        | String =>
          %quote(
            switch Dict.get(obj, field.name) {
            | Some(JSON.String(value)) => Some(value)
            | _ => None
            }
          )
        | Int =>
          %quote(
            switch Dict.get(obj, field.name) {
            | Some(JSON.Number(value)) => Some(Float.toInt(value))
            | _ => None
            }
          )
        | Bool =>
          %quote(
            switch Dict.get(obj, field.name) {
            | Some(JSON.Boolean(value)) => Some(value)
            | _ => None
            }
          )
        | _ => compileError("makeJsonDecoder only supports string, int, and bool fields")
        },
      ))

      %quote(
        (json: JSON.t) =>
          switch json {
          | JSON.Object(obj) => %splice(Code.recordOption(name, decodedFields))
          | _ => None
          }
      )
    | _ => compileError("makeJsonDecoder only supports record types")
    }
  }

let encodeUser: user => JSON.t = %comptime(makeJsonEncoder())

let decodeUser: JSON.t => option<user> = %comptime(makeJsonDecoder())

let ada = {name: "Ada", age: 42, active: true}
let encodedAda = encodeUser(ada)
let decodedAda = decodeUser(encodedAda)

Console.log(encodedAda)
Console.log(decodedAda)
