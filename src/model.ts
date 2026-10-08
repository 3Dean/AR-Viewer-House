import { Box3, Group, Mesh, Texture, Vector3 } from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import type { House } from './catalog';

export async function loadHouse(house: House, progress: (percent?: number) => void): Promise<Group> {
  if (!house.url) throw new Error('This house is not available yet.');
  const gltf = await new GLTFLoader().loadAsync(house.url, event => progress(event.total ? Math.round(event.loaded / event.total * 100) : undefined));
  const normalized = new Group();
  normalized.add(gltf.scene);
  gltf.scene.rotation.y += house.frontRotation;
  normalized.updateMatrixWorld(true);
  const bounds = new Box3().setFromObject(normalized);
  if (bounds.isEmpty()) { disposeModel(normalized); throw new Error('The house contains no visible geometry.'); }
  // Provisional bounding-box corner. Verify facade and foundation before field use.
  gltf.scene.position.sub(new Vector3(bounds.min.x, bounds.min.y, bounds.min.z));
  normalized.updateMatrixWorld(true);
  return normalized;
}

export function disposeModel(root: Group): void {
  const textures = new Set<Texture>();
  root.traverse(object => {
    if (!(object instanceof Mesh)) return;
    object.geometry.dispose();
    for (const material of Array.isArray(object.material) ? object.material : [object.material]) {
      for (const value of Object.values(material)) if (value instanceof Texture) textures.add(value);
      material.dispose();
    }
  });
  textures.forEach(texture => texture.dispose());
}
