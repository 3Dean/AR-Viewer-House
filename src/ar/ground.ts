import { Vector3 } from 'three';

/** Intersect an attitude-space camera ray with an assumed level ground plane. */
export function groundOffset(direction: Vector3, phoneHeightMeters: number): Vector3 | undefined {
  if (!Number.isFinite(phoneHeightMeters) || phoneHeightMeters < 0.3 || phoneHeightMeters > 2.5) return;
  if (direction.y > -0.2) return;
  const distance = -phoneHeightMeters / direction.y;
  if (distance > 8) return;
  return direction.clone().multiplyScalar(distance);
}
