import assert from "node:assert/strict";

import {
  ada,
  agePair,
  copyAnimal,
  copyColor,
  copyInts,
  copyPair,
  copyResult,
  copyShape,
  copyUser,
  decodeAnimal,
  decodeColor,
  decodeInts,
  decodePair,
  decodeResult,
  decodeShape,
  decodeUser,
  encodeAnimal,
  encodeColor,
  encodedAda,
  encodedColor,
  encodedFox,
  encodedNumbers,
  encodedPair,
  encodedScore,
  encodedShape,
  encodeInts,
  encodePair,
  encodeResult,
  encodeShape,
  encodeUser,
  favoriteColor,
  fox,
  greeting,
  numbers,
  sampleShape,
  score,
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

assert.deepEqual(encodedPair, ["Ada", 42]);
assert.deepEqual(encodePair(agePair), encodedPair);
assert.deepEqual(decodePair(encodedPair), agePair);
assert.deepEqual(copyPair(agePair), agePair);

assert.equal(encodedColor, "Green");
assert.equal(encodeColor(favoriteColor), encodedColor);
assert.equal(decodeColor(encodedColor), favoriteColor);
assert.equal(copyColor(favoriteColor), favoriteColor);

assert.deepEqual(encodedShape, {
  tag: "Rect",
  value: [3, 4],
});
assert.deepEqual(encodeShape(sampleShape), encodedShape);
assert.deepEqual(decodeShape(encodedShape), sampleShape);
assert.deepEqual(copyShape(sampleShape), sampleShape);

assert.deepEqual(encodedNumbers, [1, 2, 3]);
assert.deepEqual(encodeInts(numbers), encodedNumbers);
assert.deepEqual(decodeInts(encodedNumbers), numbers);
assert.deepEqual(copyInts(numbers), numbers);

assert.deepEqual(encodedScore, {
  tag: "Ok",
  value: 7,
});
assert.deepEqual(encodeResult(score), encodedScore);
assert.deepEqual(decodeResult(encodedScore), score);
assert.deepEqual(copyResult(score), score);

console.log("comptime poc passed");
