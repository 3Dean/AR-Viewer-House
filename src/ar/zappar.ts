import * as Zappar from '@zappar/zappar-threejs';
import type { WebGLRenderer } from 'three';

/** Provider boundary: metric initialization and outdoor accuracy still require validation. */
export function createTracking(renderer: WebGLRenderer) {
  Zappar.glContextSet(renderer.getContext());
  const camera = new Zappar.Camera({ zNear: 0.05, zFar: 250 });
  const tracker = new Zappar.InstantWorldTracker();
  const anchor = new Zappar.InstantWorldAnchorGroup(camera, tracker);
  return {
    camera, anchor,
    requestPermission: () => Zappar.permissionRequest(),
    start: () => camera.start(),
    update: () => camera.updateFrame(renderer),
    setAnchorOffset: (x: number, y: number, z: number) => tracker.setAnchorPoseFromCameraOffset(x, y, z),
    stop: () => camera.stop(),
  };
}
