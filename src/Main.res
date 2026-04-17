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

type pair = (string, int)

type color =
  | Red
  | Green
  | Blue

type userFieldValue = %comptime({
  let makeVariantFromFields = fields => Variant({
    constructors: fields->Array.map(field => Constructor({
      name: field.name->String.capitalize,
      payload: Single(field.typ),
    })),
  })
  let makeVariantFromRecord = _witness =>
    switch reflect() {
    | Record({fields}) => makeVariantFromFields(fields)
    | _ => failwith("userFieldValue only supports records")
    }
  makeVariantFromRecord(
    module(
      {
        type t = user
      }
    ),
  )
})

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
    | List(inner) => JSON.Array(value->List.toArray->Array.map(item => encodeByType(inner, item)))
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
    | Variant({constructors}) => encodeVariant(constructors, value)
    }

and encodeVariant:
  type a. (array<constructor<a>>, a) => JSON.t =
  (constructors, value) => {
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

and decodeJsonList:
  type a. (array<JSON.t>, JSON.t => option<a>) => option<list<a>> =
  (values, decode) =>
    Array.reduceRight(values, Some(list{}), (acc, json) =>
      switch (decode(json), acc) {
      | (Some(value), Some(values)) => Some(list{value, ...values})
      | _ => None
      }
    )

and decodeByType:
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
      | JSON.Object(obj) => decodeRecordFromObject(fields, obj)
      | _ => None
      }
    | Tuple({items}) =>
      switch json {
      | JSON.Array(values) => decodeTupleFromArray(items, values)
      | _ => None
      }
    | Variant({constructors}) =>
      if allConstructorsNoPayload(constructors) {
        switch json {
        | JSON.String(tag) => decodeEnumVariant(constructors, tag)
        | _ => None
        }
      } else {
        switch json {
        | JSON.Object(obj) =>
          switch Dict.get(obj, "tag") {
          | Some(JSON.String(tag)) => decodeTaggedVariant(constructors, tag, obj)
          | _ => None
          }
        | _ => None
        }
      }
    }

and decodeRecordFromObject:
  type a. (array<field<a>>, dict<JSON.t>) => option<a> =
  (fields, obj) => {
    let finish = (_obj, builder) => Some(builder)

    let addField = (next, field) =>
      (obj, builder) =>
        switch Dict.get(obj, field.name) {
        | Some(valueJson) =>
          switch decodeByType(field.typ, valueJson) {
          | Some(value) =>
            let nextBuilder = Dict.copy(builder)
            Dict.set(nextBuilder, field.name, value)
            next(obj, nextBuilder)
          | None => None
          }
        | None => None
        }

    Array.reduceRight(fields, finish, addField)(obj, Dict.make())
  }

and decodeTupleFromArray:
  type a. (array<item<a>>, array<JSON.t>) => option<a> =
  (items, values) => {
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
  }

and decodeEnumVariant:
  type a. (array<constructor<a>>, string) => option<a> =
  (constructors, tag) => {
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
  }

and decodeTaggedVariant:
  type a. (array<constructor<a>>, string, dict<JSON.t>) => option<a> =
  (constructors, tag, obj) => {
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
  }

and copyByType:
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
    | List(inner) => value->List.toArray->Array.map(item => copyByType(inner, item))->List.fromArray
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
    | Variant({constructors}) => copyVariant(constructors, value)
    }

and copyVariant:
  type a. (array<constructor<a>>, a) => a =
  (constructors, value) => {
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
          | Some(payload) => constructor.make(copyByType(Tuple({items: items}), payload))
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

let makeJsonDecoder:
  type t. unit => JSON.t => option<t> =
  () => {
    let desc = reflect()
    (json: JSON.t) => decodeByType(desc, json)
  }

let makeCopy:
  type t. unit => t => t =
  () => {
    let desc = reflect()
    (value: t) => copyByType(desc, value)
  }

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

let encodeUser: user => JSON.t = %comptime(makeJsonEncoder())
let decodeUser: JSON.t => option<user> = %comptime(makeJsonDecoder())
let copyUser: user => user = %comptime(makeCopy())

let encodeAnimal: animal => JSON.t = %comptime(makeJsonEncoder())
let decodeAnimal: JSON.t => option<animal> = %comptime(makeJsonDecoder())
let copyAnimal: animal => animal = %comptime(makeCopy())

let encodePair: pair => JSON.t = %comptime(makeJsonEncoder())
let decodePair: JSON.t => option<pair> = %comptime(makeJsonDecoder())
let copyPair: pair => pair = %comptime(makeCopy())

let encodeColor: color => JSON.t = %comptime(makeJsonEncoder())
let decodeColor: JSON.t => option<color> = %comptime(makeJsonDecoder())
let copyColor: color => color = %comptime(makeCopy())
let allColors: array<color> = %comptime(makeAllCases())

let encodeUserFieldValue: userFieldValue => JSON.t = %comptime(makeJsonEncoder())
let decodeUserFieldValue: JSON.t => option<userFieldValue> = %comptime(makeJsonDecoder())
let copyUserFieldValue: userFieldValue => userFieldValue = %comptime(makeCopy())

let encodeShape: shape => JSON.t = %comptime(makeJsonEncoder())
let decodeShape: JSON.t => option<shape> = %comptime(makeJsonDecoder())
let copyShape: shape => shape = %comptime(makeCopy())

let encodeInts: list<int> => JSON.t = %comptime(makeJsonEncoder())
let decodeInts: JSON.t => option<list<int>> = %comptime(makeJsonDecoder())
let copyInts: list<int> => list<int> = %comptime(makeCopy())

let encodeResult: result<int, string> => JSON.t = %comptime(makeJsonEncoder())
let decodeResult: JSON.t => option<result<int, string>> = %comptime(makeJsonDecoder())
let copyResult: result<int, string> => result<int, string> = %comptime(makeCopy())

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
let fox = {species: "Fox", age: 5, wild: true}
let agePair = ("Ada", 42)
let favoriteColor = Green
let userNameField = Name("Ada")
let userAgeField = Age(42)
let userActiveField = Active(true)
let sampleShape = Rect(3., 4.)
let numbers = list{1, 2, 3}
let score = Ok(7)

let encodedAda = encodeUser(ada)
let encodedFox = encodeAnimal(fox)
let encodedPair = encodePair(agePair)
let encodedColor = encodeColor(favoriteColor)
let encodedUserAgeField = encodeUserFieldValue(userAgeField)
let encodedShape = encodeShape(sampleShape)
let encodedNumbers = encodeInts(numbers)
let encodedScore = encodeResult(score)

let copiedAda = copyUser(ada)

Console.log(three)
Console.log(greeting)
Console.log(encodedAda)
Console.log(decodeUser(encodedAda))
Console.log(copiedAda)
Console.log(encodedFox)
Console.log(decodeAnimal(encodedFox))
Console.log(copyAnimal(fox))
Console.log(encodedPair)
Console.log(decodePair(encodedPair))
Console.log(copyPair(agePair))
Console.log(encodedColor)
Console.log(decodeColor(encodedColor))
Console.log(copyColor(favoriteColor))
Console.log(allColors)
Console.log(userNameField)
Console.log(userAgeField)
Console.log(userActiveField)
Console.log(encodedUserAgeField)
Console.log(decodeUserFieldValue(encodedUserAgeField))
Console.log(copyUserFieldValue(userActiveField))
Console.log(encodedShape)
Console.log(decodeShape(encodedShape))
Console.log(copyShape(sampleShape))
Console.log(encodedNumbers)
Console.log(decodeInts(encodedNumbers))
Console.log(copyInts(numbers))
Console.log(encodedScore)
Console.log(decodeResult(encodedScore))
Console.log(copyResult(score))
