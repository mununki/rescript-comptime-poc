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

let rec copyByType:
  type a. (typeDesc<a>, a) => a =
  (desc, value) =>
    switch desc {
    | String => value
    | Int => value
    | Float => value
    | Bool => value
    | Json => value
    | Option(inner) =>
      switch value {
      | Some(value) => Some(copyByType(inner, value))
      | None => None
      }
    | Array(inner) => value->Array.map(item => copyByType(inner, item))
    | List(inner) =>
      value->List.toArray->Array.map(item => copyByType(inner, item))->List.fromArray
    | Record({fields}) =>
      fields->Array.reduce(Dict.make(), (builder, field) => {
        let nextBuilder = Dict.copy(builder)
        Dict.set(nextBuilder, field.name, copyByType(field.typ, field.get(value)))
        nextBuilder
      })
    | Tuple({items}) =>
      items->Array.reduce(Dict.make(), (builder, item) => {
        let nextBuilder = Dict.copy(builder)
        Dict.set(nextBuilder, item.index, copyByType(item.typ, item.get(value)))
        nextBuilder
      })
    | Variant({constructors}) =>
      let finish = _ => JsError.throwWithMessage("variant value did not match any constructor")

      let addConstructor = (next, constructor) =>
        value =>
          switch constructor.payload {
          | NoPayload =>
            switch constructor.unpack(value) {
            | Some(_) => constructor.make()
            | None => next(value)
            }
          | Single(inner) =>
            switch constructor.unpack(value) {
            | Some(payload) => constructor.make(copyByType(inner, payload))
            | None => next(value)
            }
          | Tuple({items}) =>
            switch constructor.unpack(value) {
            | Some(payload) =>
              constructor.make(copyByType(Tuple({items: items}), payload))
            | None => next(value)
            }
          }

      Array.reduceRight(constructors, finish, addConstructor)(value)
    }

let makeCopy:
  type t. unit => t => t =
  () => {
    let desc = reflect()
    (value: t) => copyByType(desc, value)
  }

let copyUser: user => user = %comptime(makeCopy())
let copyPair: pair => pair = %comptime(makeCopy())
let copyColor: color => color = %comptime(makeCopy())
let copyShape: shape => shape = %comptime(makeCopy())
let copyInts: list<int> => list<int> = %comptime(makeCopy())
let copyResult: result<int, string> => result<int, string> = %comptime(makeCopy())

let ada: user = {name: "Ada", age: 42, active: true}
let agePair: pair = ("Ada", 42)
let favoriteColor = Green
let sampleShape = Rect(3., 4.)
let numbers = list{1, 2, 3}
let score = Ok(7)

let copiedAda = copyUser(ada)
let copiedPair = copyPair(agePair)
let copiedColor = copyColor(favoriteColor)
let copiedShape = copyShape(sampleShape)
let copiedNumbers = copyInts(numbers)
let copiedScore = copyResult(score)

Console.log(copiedAda)
Console.log(copiedPair)
Console.log(copiedColor)
Console.log(copiedShape)
Console.log(copiedNumbers)
Console.log(copiedScore)
