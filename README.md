# rescript-comptime-poc

Small standalone POC project for exercising the `comptime` prototype in the sibling `../rescript` checkout.

## Assumptions

- The compiler repo lives at `/Users/mununki/github/mununki/rescript`
- That checkout is on the `poc-comptime` branch
- The compiler repo has already been rebuilt after the `comptime` changes

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

The project uses local `link:` dependencies so `node_modules/rescript` points at the sibling compiler checkout.

## Proving Compile-Time Evaluation

`three` and `greeting` show valid `%comptime(...)` expressions, but their final JS is not a strong proof on its own because ordinary compiler optimizations can also constant-fold simple expressions.

The direct proof is the commented example in [`src/Main.res`](./src/Main.res):

```rescript
let broken: int = %comptime(compileError("ran during compilation"))
```

If you uncomment it and run:

```sh
pnpm build
```

the build should fail during compilation, before JS is emitted. That demonstrates that `%comptime(...)` is being evaluated by the compiler.
