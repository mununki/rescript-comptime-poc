import assert from "node:assert/strict";

import {
  ada,
  copyAnimal,
  copyUser,
  decodeAnimal,
  decodeUser,
  encodeAnimal,
  encodeUser,
  encodedAda,
  encodedFox,
  fox,
  greeting,
  three,
} from "./src/Main.mjs";

assert.equal(three, 3);
assert.equal(greeting, "comptime");
assert.deepEqual(encodedAda, {
  name: "Ada",
  age: 42,
  active: true,
});
assert.deepEqual(encodeUser(ada), encodedAda);
assert.deepEqual(decodeUser(encodedAda), ada);
assert.deepEqual(copyUser(ada), ada);
assert.equal(decodeUser("nope"), undefined);
assert.deepEqual(encodedFox, {
  species: "Fox",
  age: 5,
  wild: true,
});
assert.deepEqual(encodeAnimal(fox), encodedFox);
assert.deepEqual(decodeAnimal(encodedFox), fox);
assert.deepEqual(copyAnimal(fox), fox);
assert.equal(decodeAnimal("nope"), undefined);

console.log("comptime poc passed");
