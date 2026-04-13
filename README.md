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
