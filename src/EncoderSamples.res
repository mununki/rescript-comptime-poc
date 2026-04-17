open Comptime

type user = {
  name: string,
  age: int,
  active: bool,
}

type pair = (string, int)

type color =
  | Red
  | Green
  | Blue

type shape =
  | Point
  | Circle(float)
  | Rect(float, float)

let allConstructorsNoPayload = constructors =>
  constructors->Array.reduce(true, (all, constructor) =>
    all &&
    switch constructor.payload {
    | NoPayload => true
    | _ => false
    }
  )

let rec encodeByType:
  type a. (typeDesc<a>, a) => JSON.t =
  (desc, value) =>
    switch desc {
    | String => JSON.String(value)
    | Int => JSON.Number(Int.toFloat(value))
    | Float => JSON.Number(value)
    | Bool => JSON.Boolean(value)
    | Json => value
    | Option(inner) =>
      switch value {
      | Some(value) => encodeByType(inner, value)
      | None => JSON.Null
      }
    | Array(inner) => JSON.Array(value->Array.map(item => encodeByType(inner, item)))
    | List(inner) =>
      JSON.Array(value->List.toArray->Array.map(item => encodeByType(inner, item)))
    | Record({fields}) =>
      JSON.Object(
        fields->Array.reduce(Dict.make(), (builder, field) => {
          let nextBuilder = Dict.copy(builder)
          Dict.set(nextBuilder, field.name, encodeByType(field.typ, field.get(value)))
          nextBuilder
        }),
      )
    | Tuple({items}) =>
      JSON.Array(items->Array.map(item => encodeByType(item.typ, item.get(value))))
    | Variant({constructors}) =>
      let encodeNoPayload = name =>
        if allConstructorsNoPayload(constructors) {
          JSON.String(name)
        } else {
          JSON.Object(dict{"tag": JSON.String(name)})
        }

      let finish = _ => JsError.throwWithMessage("variant value did not match any constructor")

      let addConstructor = (next, constructor) =>
        value =>
          switch constructor.payload {
          | NoPayload =>
            switch constructor.unpack(value) {
            | Some(_) => encodeNoPayload(constructor.name)
            | None => next(value)
            }
          | Single(inner) =>
            switch constructor.unpack(value) {
            | Some(payload) =>
              JSON.Object(
                dict{
                  "tag": JSON.String(constructor.name),
                  "value": encodeByType(inner, payload),
                },
              )
            | None => next(value)
            }
          | Tuple({items}) =>
            switch constructor.unpack(value) {
            | Some(payload) =>
              JSON.Object(
                dict{
                  "tag": JSON.String(constructor.name),
                  "value": encodeByType(Tuple({items: items}), payload),
                },
              )
            | None => next(value)
            }
          }

      Array.reduceRight(constructors, finish, addConstructor)(value)
    }

let makeJsonEncoder:
  type t. unit => t => JSON.t =
  () => {
    let desc = reflect()
    (value: t) => encodeByType(desc, value)
  }

let encodeUser: user => JSON.t = %comptime(makeJsonEncoder())
let encodePair: pair => JSON.t = %comptime(makeJsonEncoder())
let encodeColor: color => JSON.t = %comptime(makeJsonEncoder())
let encodeShape: shape => JSON.t = %comptime(makeJsonEncoder())
let encodeInts: list<int> => JSON.t = %comptime(makeJsonEncoder())
let encodeResult: result<int, string> => JSON.t = %comptime(makeJsonEncoder())

let ada: user = {name: "Ada", age: 42, active: true}
let agePair: pair = ("Ada", 42)
let favoriteColor = Green
let sampleShape = Rect(3., 4.)
let numbers = list{1, 2, 3}
let score = Ok(7)

let encodedAda = encodeUser(ada)
let encodedPair = encodePair(agePair)
let encodedColor = encodeColor(favoriteColor)
let encodedShape = encodeShape(sampleShape)
let encodedNumbers = encodeInts(numbers)
let encodedScore = encodeResult(score)

Console.log(encodedAda)
Console.log(encodedPair)
Console.log(encodedColor)
Console.log(encodedShape)
Console.log(encodedNumbers)
Console.log(encodedScore)
