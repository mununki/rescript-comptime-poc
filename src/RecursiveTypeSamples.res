open Comptime

type rec tree = {value: string, children: array<tree>}

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
    | Variant(_) => JsError.throwWithMessage("RecursiveTypeSamples only handles recursive records")
    }

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
    | Variant(_) => JsError.throwWithMessage("RecursiveTypeSamples only handles recursive records")
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

let encodeTree: tree => JSON.t = %comptime(makeJsonEncoder())
let decodeTree: JSON.t => option<tree> = %comptime(makeJsonDecoder())

let sampleTree: tree = {
  value: "root",
  children: [
    {value: "left", children: []},
    {
      value: "right",
      children: [{value: "leaf", children: []}],
    },
  ],
}

let jsonTree = JSON.Object(
  dict{
    "value": JSON.String("root"),
    "children": JSON.Array([
      JSON.Object(
        dict{
          "value": JSON.String("left"),
          "children": JSON.Array([]),
        },
      ),
      JSON.Object(
        dict{
          "value": JSON.String("right"),
          "children": JSON.Array([
            JSON.Object(
              dict{
                "value": JSON.String("leaf"),
                "children": JSON.Array([]),
              },
            ),
          ]),
        },
      ),
    ]),
  },
)

let encodedTree = encodeTree(sampleTree)
let decodedTree = decodeTree(jsonTree)

Console.log(encodedTree)
Console.log(decodedTree)
