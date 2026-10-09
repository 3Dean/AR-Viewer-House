import assert from 'node:assert/strict';
import { test } from 'node:test';
import { Vector3 } from 'three';

import { groundOffset } from '../src/ar/ground.ts';

test('downward ray lands directly beneath phone at entered height', () => {
  assert.deepEqual(groundOffset(new Vector3(0,-1,0),1.5).toArray(), [0,-1.5,0]);
});
test('angled ray estimates ground offset from height, preserving horizontal direction', () => {
  const hit = groundOffset(new Vector3(0,-1,-1).normalize(),1.5);
  assert.ok(Math.abs(hit.y + 1.5) < 1e-9);
  assert.ok(Math.abs(hit.z + 1.5) < 1e-9);
});
test('rejects horizontal, upward, distant and invalid-height placements', () => {
  for (const ray of [new Vector3(0,0,-1),new Vector3(0,1,0),new Vector3(0,-.21,-.978)]) assert.equal(groundOffset(ray,2),undefined);
  for (const height of [NaN,0,-1,3]) assert.equal(groundOffset(new Vector3(0,-1,0),height),undefined);
});
