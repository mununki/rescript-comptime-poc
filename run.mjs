import assert from "node:assert/strict";

import {greeting, three} from "./src/ComptimeValues.mjs";
import {
  ada,
  encodedAda,
  encodeUser,
  agePair,
  encodedPair,
  encodePair,
  encodedColor,
  encodedShape,
  encodedNumbers,
  encodedScore,
  encodeColor,
  encodeShape,
  favoriteColor,
  numbers,
  sampleShape,
  score,
  encodeInts,
  encodeResult,
} from "./src/EncoderSamples.mjs";
import {
  ada as decodedAdaExpected,
  agePair as decodedPairExpected,
  decodeColor,
  decodeInts,
  decodePair,
  decodeResult,
  decodeShape,
  decodeUser,
  favoriteColor as decodedColorExpected,
  jsonAda,
  jsonColor,
  jsonNumbers,
  jsonPair,
  jsonScore,
  jsonShape,
  numbers as decodedNumbersExpected,
  sampleShape as decodedShapeExpected,
  score as decodedScoreExpected,
} from "./src/DecoderSamples.mjs";
import {
  ada as copiedAdaExpected,
  agePair as copiedPairExpected,
  copiedAda,
  copiedColor,
  copiedNumbers,
  copiedPair,
  copiedScore,
  copiedShape,
  favoriteColor as copiedColorExpected,
  numbers as copiedNumbersExpected,
  sampleShape as copiedShapeExpected,
  score as copiedScoreExpected,
} from "./src/CopySamples.mjs";
import {allColors} from "./src/AllCasesSamples.mjs";
import {
  fieldLabel,
  userActiveField,
  userAgeField,
  userNameField,
} from "./src/VariantFromRecordSamples.mjs";
import {
  emptyOptionalFieldR0,
  emptyOptionalValueR0,
  fullOptionalFieldR0,
  fullOptionalValueR0,
} from "./src/OptionalRecordSamples.mjs";
import {personR0} from "./src/RecordFromVariantSamples.mjs";

assert.equal(three, 3);
assert.equal(greeting, "comptime");
assert.deepEqual(encodedAda, {
  name: "Ada",
  age: 42,
  active: true,
});
assert.deepEqual(encodeUser(ada), encodedAda);
assert.deepEqual(encodedPair, ["Ada", 42]);
assert.deepEqual(encodePair(agePair), encodedPair);
assert.equal(encodedColor, "Green");
assert.equal(encodeColor(favoriteColor), encodedColor);
assert.deepEqual(encodedShape, {
  tag: "Rect",
  value: [3, 4],
});
assert.deepEqual(encodeShape(sampleShape), encodedShape);
assert.deepEqual(encodedNumbers, [1, 2, 3]);
assert.deepEqual(encodeInts(numbers), encodedNumbers);
assert.deepEqual(encodedScore, {
  tag: "Ok",
  value: 7,
});
assert.deepEqual(encodeResult(score), encodedScore);

assert.deepEqual(decodeUser(jsonAda), decodedAdaExpected);
assert.deepEqual(decodePair(jsonPair), decodedPairExpected);
assert.equal(decodeColor(jsonColor), decodedColorExpected);
assert.deepEqual(decodeShape(jsonShape), decodedShapeExpected);
assert.deepEqual(decodeInts(jsonNumbers), decodedNumbersExpected);
assert.deepEqual(decodeResult(jsonScore), decodedScoreExpected);

assert.deepEqual(copiedAda, copiedAdaExpected);
assert.deepEqual(copiedPair, copiedPairExpected);
assert.equal(copiedColor, copiedColorExpected);
assert.deepEqual(copiedShape, copiedShapeExpected);
assert.deepEqual(copiedNumbers, copiedNumbersExpected);
assert.deepEqual(copiedScore, copiedScoreExpected);

assert.deepEqual(allColors, ["Red", "Green", "Blue"]);
assert.deepEqual(userNameField, {
  TAG: "Name",
  _0: "Ada",
});
assert.deepEqual(userAgeField, {
  TAG: "Age",
  _0: 42,
});
assert.deepEqual(userActiveField, {
  TAG: "Active",
  _0: true,
});
assert.equal(fieldLabel(userAgeField), "Age");
assert.deepEqual(emptyOptionalValueR0, {
  name: undefined,
  age: undefined,
});
assert.deepEqual(fullOptionalValueR0, {
  name: "Ada",
  age: 42,
});
assert.deepEqual(emptyOptionalFieldR0, {});
assert.deepEqual(fullOptionalFieldR0, {
  name: "Ada",
  age: 42,
});
assert.deepEqual(personR0, {
  name: "Ada",
  age: 42,
});

console.log("comptime poc passed");
