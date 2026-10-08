import './style.css';
import { AmbientLight, Box3, BufferGeometry, Color, DirectionalLight, GridHelper, Group, Line, LineBasicMaterial, Mesh, MeshBasicMaterial, PerspectiveCamera, Scene, SphereGeometry, Vector3, WebGLRenderer } from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { houses } from './catalog';
import { disposeModel, loadHouse } from './model';

document.querySelector<HTMLDivElement>('#app')!.innerHTML = `
  <header><div><h1>House on Site</h1><p>Choose a house. Explore its place on your lot.</p></div><span>Prototype · 0.1</span></header>
  <main><section class="stage" aria-label="Interactive house preview"><div class="badge">3D preview · drag to orbit, pinch to zoom</div></section>
  <aside><section class="panel"><h2>Choose your house</h2><div class="cards"></div></section>
  <section class="panel"><h2>Preview adjustments</h2>
  <label>Rotation <output id="angle">0°</output><input id="rotation" type="range" min="-180" max="180" value="0" step="1"></label>
  <label>Foundation height <output id="height">0 ft</output><input id="elevation" type="range" min="-5" max="10" value="0" step="0.25"></label>
  <div class="row"><button id="reset">Reset view</button><button id="display">Footprint view</button></div>
  <p class="note">The green pin marks the provisional front-left ground corner. Facade orientation still needs visual verification.</p>
  <button class="primary" id="ar" disabled>AR setup pending validation</button>
  <p class="note">AR placement is the next development phase. This viewer preserves model proportions; outdoor accuracy has not been validated.</p></section>
  <section class="panel"><p id="status" role="status" aria-live="polite">Loading House 1…</p></section></aside></main>`;
const stage = document.querySelector<HTMLElement>('.stage')!;
const status = document.querySelector<HTMLElement>('#status')!;
const renderer = new WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
stage.append(renderer.domElement);
const scene = new Scene();
scene.background = new Color('#e3e9e2');
scene.add(new AmbientLight(0xffffff, 2));
const sun = new DirectionalLight(0xffffff, 3); sun.position.set(-15, 30, -10); scene.add(sun);
const grid = new GridHelper(80, 40, '#8aab97', '#c5d1c6'); scene.add(grid);
const placement = new Group(); scene.add(placement);
const pin = new Mesh(new SphereGeometry(.25, 16, 12), new MeshBasicMaterial({ color: '#16744c' }));
pin.position.y = .25; placement.add(pin);
const outline = new Line(new BufferGeometry(), new LineBasicMaterial({ color: '#16744c' })); placement.add(outline);
const camera = new PerspectiveCamera(45, 1, .1, 500);
const controls = new OrbitControls(camera, renderer.domElement); controls.enableDamping = true; controls.maxDistance = 180;
let model: Group | undefined;
let selectedId = '';
let requestId = 0;
let footprint = false;
const rotation = document.querySelector<HTMLInputElement>('#rotation')!;
const elevation = document.querySelector<HTMLInputElement>('#elevation')!;
function frameModel() {
  if (!model) return;
  placement.updateMatrixWorld(true);
  const bounds = new Box3().setFromObject(model);
  const center = bounds.getCenter(new Vector3());
  const size = bounds.getSize(new Vector3()).length();
  controls.target.copy(center);
  camera.position.copy(center).add(new Vector3(-size, size * .65, -size));
  controls.update();
}
const cards = document.querySelector<HTMLElement>('.cards')!;
for (const house of houses) {
  const button = document.createElement('button');
  button.className = 'card'; button.disabled = !house.url; button.dataset.id = house.id;
  button.setAttribute('aria-pressed', 'false');
  button.innerHTML = `<span class="swatch" style="background:${house.color}"></span><span>${house.name}<small>${house.url ? '50′ × 45′ × 27′' : 'Coming soon'}</small></span>`;
  button.addEventListener('click', () => { void selectHouse(house.id); }); cards.append(button);
}
async function selectHouse(id: string) {
  const house = houses.find(item => item.id === id); if (!house?.url || id === selectedId) return;
  const ticket = ++requestId; status.textContent = `Loading ${house.name}…`;
  try {
    const next = await loadHouse(house, percent => { if (ticket === requestId) status.textContent = `Loading ${house.name}${percent === undefined ? '…' : ` · ${percent}%`}`; });
    if (ticket !== requestId) { disposeModel(next); return; }
    if (model) { placement.remove(model); disposeModel(model); }
    const dimensions = new Box3().setFromObject(next).getSize(new Vector3());
    model = next; model.visible = !footprint; placement.add(model); selectedId = id;
    outline.geometry.dispose();
    outline.geometry = new BufferGeometry().setFromPoints([
      new Vector3(0,.03,0), new Vector3(dimensions.x,.03,0),
      new Vector3(dimensions.x,.03,dimensions.z), new Vector3(0,.03,dimensions.z), new Vector3(0,.03,0),
    ]);
    cards.querySelectorAll<HTMLButtonElement>('button').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.id === id)));
    status.textContent = `${house.name} ready. Nominal size: ${house.dimensionsFeet.join(' × ')} feet (width × depth × height).`;
    frameModel();
  } catch (error) { if (ticket === requestId) status.textContent = `Could not load the house. ${error instanceof Error ? error.message : 'Please retry.'}`; }
}
rotation.addEventListener('input', () => { placement.rotation.y = Number(rotation.value) * Math.PI / 180; document.querySelector('#angle')!.textContent = `${rotation.value}°`; });
elevation.addEventListener('input', () => { placement.position.y = Number(elevation.value) * .3048; document.querySelector('#height')!.textContent = `${elevation.value} ft`; });
document.querySelector('#reset')!.addEventListener('click', () => { rotation.value = '0'; elevation.value = '0'; rotation.dispatchEvent(new Event('input')); elevation.dispatchEvent(new Event('input')); frameModel(); });
document.querySelector('#display')!.addEventListener('click', event => { footprint = !footprint; if (model) model.visible = !footprint; (event.currentTarget as HTMLButtonElement).textContent = footprint ? 'Show house' : 'Footprint view'; status.textContent = footprint ? 'Bounding footprint and origin shown.' : 'House preview shown.'; });
const resize = new ResizeObserver(() => { const { width, height } = stage.getBoundingClientRect(); renderer.setSize(width, height); camera.aspect = width / height; camera.updateProjectionMatrix(); }); resize.observe(stage);
renderer.setAnimationLoop(() => { controls.update(); renderer.render(scene, camera); });
window.addEventListener('pagehide', event => { if (event.persisted) return; renderer.setAnimationLoop(null); resize.disconnect(); controls.dispose(); if (model) disposeModel(model); outline.geometry.dispose(); outline.material.dispose(); pin.geometry.dispose(); pin.material.dispose(); grid.geometry.dispose(); if (Array.isArray(grid.material)) grid.material.forEach(material => material.dispose()); else grid.material.dispose(); renderer.dispose(); });
void selectHouse(houses[0].id);
