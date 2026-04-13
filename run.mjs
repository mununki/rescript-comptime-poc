import assert from "node:assert/strict";

import {
  ada,
  decodeUser,
  encodeUser,
  encodedAda,
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
assert.equal(JSON.stringify(encodeUser(ada)), "{\"name\":\"Ada\",\"age\":42,\"active\":true}");
assert.deepEqual(decodeUser(encodedAda), ada);
assert.equal(decodeUser("nope"), undefined);

console.log("comptime poc passed");
