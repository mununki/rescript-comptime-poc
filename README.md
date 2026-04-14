# rescript-comptime-poc

Small standalone POC project for exercising the current `comptime`
implementation in the sibling `../rescript` checkout.

The public surface used here is:

- `%comptime(...)`
- `reflect()`
- `field.name`, `field.typ`, `field.get(value)`
- `item.index`, `item.typ`, `item.get(value)`
- `constructor.name`, `constructor.payload`, `constructor.unpack(value)`, `constructor.make(payload)`

The sample includes generic:

- `makeJsonEncoder`
- `makeJsonDecoder`
- `makeCopy`

and applies them to:

- records
- tuples
- ordinary variants
- `list`
- `result`

## Assumptions

- The compiler repo lives at `/Users/mununki/github/mununki/rescript`
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

## Proving Compile-Time Evaluation

`three` and `greeting` are valid `%comptime(...)` examples, but their final JS is
not a proof by itself because ordinary compiler optimizations can also
constant-fold simple expressions.

The direct proof is the commented example in [`src/Main.res`](./src/Main.res):

```rescript
let broken: int = %comptime(failwith("ran during compilation"))
```

If you uncomment it and run:

```sh
pnpm build
```

the build should fail during compilation, before JS is emitted. That
demonstrates that `%comptime(...)` is being evaluated by the compiler.
