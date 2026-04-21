# rescript-comptime-poc

Small standalone POC project for exercising the current `comptime`
implementation in the sibling `../rescript` checkout.

This POC is intended to run against
`github.com/mununki/rescript` on the `poc-comptime` branch.

The public surface used here is intentionally small:

- `%comptime(...)` on top-level `let` bindings
- `type t = %comptime(...)` for generated type aliases
- `reflect()`
- `field.name`, `field.typ`, `field.get(value)`
- `item.index`, `item.typ`, `item.get(value)`
- `constructor.name`, `constructor.payload`, `constructor.unpack(value)`, `constructor.make(payload)`
- anonymous module witnesses such as `module({type t = user})` for type-level reflection

The sample includes generic:

- `makeJsonEncoder`
- `makeJsonDecoder`
- `makeCopy`
- `makeAllCases`
- `makeVariantFromRecord`
- `makeOptionalRecord`
- `makeRecordFromVariant`

and applies them to:

- records
- tuples
- ordinary variants
- `list`
- `result`
- generated type aliases derived from existing reflected types

The source tree is split by use case:

- `src/EncoderSamples.res`: `makeJsonEncoder`
- `src/DecoderSamples.res`: `makeJsonDecoder`
- `src/CopySamples.res`: `makeCopy`
- `src/AllCasesSamples.res`: `makeAllCases`
- `src/VariantFromRecordSamples.res`: `makeVariantFromRecord`
- `src/OptionalRecordSamples.res`: `makeOptionalRecord`
- `src/RecordFromVariantSamples.res`: `makeRecordFromVariant`
- `src/ComptimeValues.res`: direct compile-time evaluation examples

Each sample module logs its own values at top level, so you can inspect a
single example directly with Node:

```sh
node src/EncoderSamples.mjs
node src/DecoderSamples.mjs
node src/CopySamples.mjs
node src/AllCasesSamples.mjs
node src/VariantFromRecordSamples.mjs
node src/OptionalRecordSamples.mjs
node src/RecordFromVariantSamples.mjs
node src/ComptimeValues.mjs
```

## Assumptions

- The compiler repo lives at `/Users/mununki/github/mununki/rescript`
- That checkout is `github.com/mununki/rescript` on the `poc-comptime` branch
- That checkout has already been rebuilt after the `comptime` changes

## Local Setup

From the compiler checkout:

```sh
cd /Users/mununki/github/mununki/rescript
opam exec -- dune build @install
node scripts/copyExes.js --compiler
```

Then in this POC project:

```sh
cd /Users/mununki/github/mununki/rescript-comptime-poc
pnpm install
pnpm build
pnpm test
```

The project uses local `link:` dependencies, so `node_modules/rescript` points
at the sibling compiler checkout.

When a comptime helper needs to return an actual record value, the intended
surface stays close to ordinary ReScript record syntax:

```rescript
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
```

This keeps the decoder-style "build a record from reflected fields" path close
to ordinary record update syntax. The compiler still lowers it to its existing
internal builder representation.

## Type-Level Example

The POC includes a generated type alias that turns a record into a variant
without introducing a separate `Type.*` builder API:

```rescript
type userFieldValue = %comptime(
  {
    let makeVariantFromFields = fields =>
      Variant({
        constructors:
          fields->Array.map(field =>
            Constructor({
              name: field.name->String.capitalize,
              payload: Single(field.typ),
            })
          ),
      })
    let makeVariantFromRecord = _witness =>
      switch reflect() {
      | Record({fields}) => makeVariantFromFields(fields)
      | _ => failwith("userFieldValue only supports records")
      }
    makeVariantFromRecord(module({type t = user}))
  }
)
```

Additional generated-type samples:

```rescript
type r0 = {name: string, age: int}
type optionalValueR0 = %comptime({
  let makeOptionRecord = _witness =>
    switch reflect() {
    | Record({fields}) =>
      Record({
        fields:
          fields->Array.map(field => {
            name: field.name,
            typ: Option(field.typ),
          }),
      })
    | _ => failwith("makeOptionRecord only supports records")
    }
  makeOptionRecord(module({type t = r0}))
})

type optionalFieldR0 = %comptime({
  let makeOptionalFieldRecord = _witness =>
    switch reflect() {
    | Record({fields}) =>
      Record({
        fields:
          fields->Array.map(field => {
            name: field.name,
            typ: Optional(field.typ),
          }),
      })
    | _ => failwith("makeOptionalFieldRecord only supports records")
    }
  makeOptionalFieldRecord(module({type t = r0}))
})

type v0 =
  | Name(string)
  | Age(int)

type r0 = %comptime({
  let makeRecordFromVariant = _witness =>
    switch reflect() {
    | Variant({constructors}) =>
      Record({
        fields:
          constructors->Array.map(constructor => {
            name: switch constructor.name {
            | "Name" => "name"
            | "Age" => "age"
            | _ => failwith("unsupported constructor")
            },
            typ: switch constructor.payload {
            | Single(desc) => desc
            | _ => failwith("single-payload constructors only")
            },
          }),
      })
    | _ => failwith("makeRecordFromVariant only supports variants")
    }
  makeRecordFromVariant(module({type t = v0}))
})
```

## Proving Compile-Time Evaluation

`three` and `greeting` are valid `%comptime(...)` examples, but their final JS is
not proof by itself because ordinary compiler optimizations can also
constant-fold simple expressions.

The direct proof is the commented example in [`src/ComptimeValues.res`](./src/ComptimeValues.res):

```rescript
let broken: int = %comptime(failwith("ran during compilation"))
```

If you uncomment it and run:

```sh
pnpm build
```

the build fails during compilation, before JS is emitted. That demonstrates
that `%comptime(...)` is being evaluated by the compiler.
