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

let decodeJsonList = (values, decode) =>
  Array.reduceRight(values, Some(list{}), (acc, json) =>
    switch (decode(json), acc) {
    | (Some(value), Some(values)) => Some(list{value, ...values})
    | _ => None
    }
  )

let rec decodeByType:
  type a. (typeDesc<a>, JSON.t) => option<a> =
  (desc, json) =>
    switch desc {
    | String =>
      switch json {
      | JSON.String(value) => Some(value)
      | _ => None
      }
    | Int =>
      switch json {
      | JSON.Number(value) => Some(Float.toInt(value))
      | _ => None
      }
    | Float =>
      switch json {
      | JSON.Number(value) => Some(value)
      | _ => None
      }
    | Bool =>
      switch json {
      | JSON.Boolean(value) => Some(value)
      | _ => None
      }
    | Json => Some(json)
    | Option(inner) =>
      switch json {
      | JSON.Null => Some(None)
      | _ =>
        switch decodeByType(inner, json) {
        | Some(value) => Some(Some(value))
        | None => None
        }
      }
    | Array(inner) =>
      switch json {
      | JSON.Array(values) =>
        switch decodeJsonList(values, value => decodeByType(inner, value)) {
        | Some(values) => Some(values->List.toArray)
        | None => None
        }
      | _ => None
      }
    | List(inner) =>
      switch json {
      | JSON.Array(values) => decodeJsonList(values, value => decodeByType(inner, value))
      | _ => None
      }
    | Record({fields}) =>
      switch json {
      | JSON.Object(obj) =>
        let finish = (_obj, builder) => Some(builder)

        let addField = (next, field) =>
          (obj, r) =>
            switch Dict.get(obj, field.name) {
            | Some(valueJson) =>
              switch decodeByType(field.typ, valueJson) {
              | Some(value) => next(obj, {...r, field: value})
              | None => None
              }
            | None => None
            }

        let seed = {}
        Array.reduceRight(fields, finish, addField)(obj, seed)
      | _ => None
      }
    | Tuple({items}) =>
      switch json {
      | JSON.Array(values) =>
        let finish = (_values, builder) => Some(builder)

        let addItem = (next, item) =>
          (values, builder) =>
            switch values[item.index] {
            | Some(valueJson) =>
              switch decodeByType(item.typ, valueJson) {
              | Some(value) =>
                let nextBuilder = Dict.copy(builder)
                Dict.set(nextBuilder, item.index, value)
                next(values, nextBuilder)
              | None => None
              }
            | None => None
            }

        Array.reduceRight(items, finish, addItem)(values, Dict.make())
      | _ => None
      }
    | Variant({constructors}) =>
      if allConstructorsNoPayload(constructors) {
        switch json {
        | JSON.String(tag) =>
          let finish = _ => None

          let addConstructor = (next, constructor) =>
            tag =>
              switch constructor.payload {
              | NoPayload =>
                if constructor.name == tag {
                  Some(constructor.make())
                } else {
                  next(tag)
                }
              | _ => next(tag)
              }

          Array.reduceRight(constructors, finish, addConstructor)(tag)
        | _ => None
        }
      } else {
        switch json {
        | JSON.Object(obj) =>
          switch Dict.get(obj, "tag") {
          | Some(JSON.String(tag)) =>
            let finish = (_tag, _obj) => None

            let addConstructor = (next, constructor) =>
              (tag, obj) =>
                if constructor.name == tag {
                  switch constructor.payload {
                  | NoPayload => Some(constructor.make())
                  | Single(inner) =>
                    switch Dict.get(obj, "value") {
                    | Some(valueJson) =>
                      switch decodeByType(inner, valueJson) {
                      | Some(value) => Some(constructor.make(value))
                      | None => None
                      }
                    | None => None
                    }
                  | Tuple({items}) =>
                    switch Dict.get(obj, "value") {
                    | Some(valueJson) =>
                      switch decodeByType(Tuple({items: items}), valueJson) {
                      | Some(value) => Some(constructor.make(value))
                      | None => None
                      }
                    | None => None
                    }
                  }
                } else {
                  next(tag, obj)
                }

            Array.reduceRight(constructors, finish, addConstructor)(tag, obj)
          | _ => None
          }
        | _ => None
        }
      }
    }

let makeJsonDecoder:
  type t. unit => JSON.t => option<t> =
  () => {
    let desc = reflect()
    (json: JSON.t) => decodeByType(desc, json)
  }

let decodeUser: JSON.t => option<user> = %comptime(makeJsonDecoder())
let decodePair: JSON.t => option<pair> = %comptime(makeJsonDecoder())
let decodeColor: JSON.t => option<color> = %comptime(makeJsonDecoder())
let decodeShape: JSON.t => option<shape> = %comptime(makeJsonDecoder())
let decodeInts: JSON.t => option<list<int>> = %comptime(makeJsonDecoder())
let decodeResult: JSON.t => option<result<int, string>> = %comptime(makeJsonDecoder())

let ada: user = {name: "Ada", age: 42, active: true}
let agePair: pair = ("Ada", 42)
let favoriteColor = Green
let sampleShape = Rect(3., 4.)
let numbers = list{1, 2, 3}
let score = Ok(7)

let jsonAda = JSON.Object(
  dict{
    "name": JSON.String("Ada"),
    "age": JSON.Number(42.),
    "active": JSON.Boolean(true),
  },
)

let jsonPair = JSON.Array([JSON.String("Ada"), JSON.Number(42.)])
let jsonColor = JSON.String("Green")

let jsonShape = JSON.Object(
  dict{
    "tag": JSON.String("Rect"),
    "value": JSON.Array([JSON.Number(3.), JSON.Number(4.)]),
  },
)

let jsonNumbers = JSON.Array([JSON.Number(1.), JSON.Number(2.), JSON.Number(3.)])

let jsonScore = JSON.Object(
  dict{
    "tag": JSON.String("Ok"),
    "value": JSON.Number(7.),
  },
)

let decodedAda = decodeUser(jsonAda)
let decodedPair = decodePair(jsonPair)
let decodedColor = decodeColor(jsonColor)
let decodedShape = decodeShape(jsonShape)
let decodedNumbers = decodeInts(jsonNumbers)
let decodedScore = decodeResult(jsonScore)

Console.log(decodedAda)
Console.log(decodedPair)
Console.log(decodedColor)
Console.log(decodedShape)
Console.log(decodedNumbers)
Console.log(decodedScore)
