import './style.css';
import { AmbientLight, Box3, BufferGeometry, Color, DirectionalLight, GridHelper, Group, Line, LineBasicMaterial, Mesh, MeshBasicMaterial, PerspectiveCamera, Raycaster, Scene, SphereGeometry, Vector2, Vector3, WebGLRenderer } from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { houses } from './catalog';
import { disposeModel, loadHouse } from './model';
import { groundOffset } from './ar/ground';
import type { createTracking } from './ar/zappar';

document.querySelector<HTMLDivElement>('#app')!.innerHTML = `
  <header><div><h1>House on Site</h1><p>Choose a house. Explore its place on your lot.</p></div><span>Prototype · 0.1</span></header>
  <main><section class="stage" aria-label="Interactive house preview"><div class="badge">3D preview · drag to orbit, pinch to zoom</div></section>
  <aside><section class="panel"><h2>Choose your house</h2><div class="cards"></div></section>
  <section class="panel"><h2>Preview adjustments</h2>
  <label>Rotation <output id="angle">0°</output><input id="rotation" type="range" min="-180" max="180" value="0" step="1"></label>
  <label>Foundation height <output id="height">0 ft</output><input id="elevation" type="range" min="-5" max="10" value="0" step="0.25"></label>
  <div class="row"><button id="reset">Reset view</button><button id="display">Footprint view</button></div>
  <p class="note">The green pin marks the provisional front-left ground corner. Facade orientation still needs visual verification.</p>
  <label>Phone height above ground (feet)<input id="phone-height" type="number" min="1" max="8" step="0.1" value="4.5"></label>
  <button class="primary" id="ar" disabled>Start AR placement</button>
  <div id="ar-controls" hidden><p>Aim at nearby ground and tap the camera view to place the front-left pin.</p>
  <div class="row"><button id="lock">Lock placement</button><button id="reposition">Place again</button><button id="exit-ar">Exit AR</button></div>
  <p>Move in house directions · 1 foot per tap</p><div class="row"><button data-move="left">Left</button><button data-move="right">Right</button><button data-move="front">Front</button><button data-move="rear">Rear</button></div></div>
  <p class="note">Placement uses estimated phone height and a level ground assumption. One-foot accuracy and 100-foot walking have not been validated.</p></section>
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
const arButton = document.querySelector<HTMLButtonElement>('#ar')!;
const badge = document.querySelector<HTMLElement>('.badge')!;
type Tracking = ReturnType<typeof createTracking>;
let tracking: Tracking | undefined;
let arState: 'preview' | 'starting' | 'placing' | 'adjusting' | 'locked' = 'preview';
const raycaster = new Raycaster();
function syncARControls() {
  const active = arState !== 'preview' && arState !== 'starting';
  document.querySelector<HTMLElement>('#ar-controls')!.hidden = !active;
  document.querySelector<HTMLButtonElement>('#lock')!.disabled = arState === 'placing';
  document.querySelector<HTMLButtonElement>('#lock')!.textContent = arState === 'locked' ? 'Adjust placement' : 'Lock placement';
  const frozen = arState === 'locked' || arState === 'placing' || arState === 'starting';
  rotation.disabled = frozen; elevation.disabled = frozen;
  document.querySelector<HTMLButtonElement>('#reset')!.disabled = active || arState === 'starting';
  document.querySelectorAll<HTMLButtonElement>('[data-move]').forEach(button => { button.disabled = arState !== 'adjusting'; });
  arButton.disabled = !model || arState !== 'preview';
  document.body.classList.toggle('ar-active', active);
}
function exitAR(message = 'Returned to 3D preview.') {
  if (tracking) { scene.add(placement); scene.remove(tracking.anchor); tracking.dispose(); tracking = undefined; }
  arState = 'preview'; placement.visible = true; grid.visible = true; controls.enabled = true;
  placement.position.set(0, Number(elevation.value) * .3048, 0);
  scene.background = new Color('#e3e9e2'); badge.textContent = '3D preview · drag to orbit, pinch to zoom';
  syncARControls(); frameModel(); status.textContent = message;
}
arButton.addEventListener('click', async () => {
  if (arState !== 'preview' || !model) return;
  if (!window.isSecureContext) { status.textContent = 'Open this page over HTTPS to use the camera. The 3D preview remains available.'; return; }
  arState = 'starting'; syncARControls(); status.textContent = 'Preparing AR. Continue through the camera and motion permission prompts.';
  try {
    const sdk = await import('./ar/zappar');
    tracking = sdk.createTracking(renderer);
    if (tracking.incompatible()) throw new Error('This browser does not support the AR camera. Try Safari on iPhone or Chrome on Android.');
    // SDK permission UI supplies a fresh user gesture after the asynchronous import.
    const { permissionRequestUI } = await import('@zappar/zappar-threejs');
    const granted = await permissionRequestUI();
    if (!granted) throw new Error('Camera or motion access was denied. Allow access in browser settings and try again.');
    tracking.start(); scene.background = tracking.camera.backgroundTexture;
    scene.add(tracking.anchor); tracking.anchor.add(placement);
    controls.enabled = false; grid.visible = false; placement.visible = false;
    arState = 'placing'; badge.textContent = 'Aim down and tap nearby ground · estimated placement';
    syncARControls(); status.textContent = 'Scan nearby surroundings briefly, then tap the ground near your feet.';
  } catch (error) { exitAR(error instanceof Error ? error.message : 'AR could not start. Please retry.'); }
});
renderer.domElement.addEventListener('click', event => {
  if (arState !== 'placing' || !tracking) return;
  tracking.update(); tracking.camera.updateMatrixWorld(true);
  const rect = renderer.domElement.getBoundingClientRect();
  raycaster.setFromCamera(new Vector2((event.clientX-rect.left)/rect.width*2-1, -(event.clientY-rect.top)/rect.height*2+1), tracking.camera);
  const height = Number(document.querySelector<HTMLInputElement>('#phone-height')!.value) * .3048;
  const offset = groundOffset(raycaster.ray.direction, height);
  if (!offset) { status.textContent = 'Enter a phone height between 1 and 8 feet, and aim farther down at nearby level ground.'; return; }
  offset.applyQuaternion(tracking.camera.quaternion.clone().invert());
  tracking.setAnchorOffset(offset.x, offset.y, offset.z);
  placement.position.set(0, Number(elevation.value)*.3048, 0); placement.visible = true;
  arState = 'adjusting'; badge.textContent = 'Adjust house direction and position, then lock'; syncARControls();
  status.textContent = 'Pin placed using estimated ground distance. Adjust the house to your intended location.';
});
document.querySelector('#lock')!.addEventListener('click', () => { if (arState === 'adjusting') arState = 'locked'; else if (arState === 'locked') arState = 'adjusting'; syncARControls(); badge.textContent = arState === 'locked' ? 'Placement locked · tracking continues' : 'Adjust house placement'; });
document.querySelector('#reposition')!.addEventListener('click', () => { arState = 'placing'; placement.visible = false; syncARControls(); badge.textContent = 'Tap nearby ground to place again'; });
document.querySelector('#exit-ar')!.addEventListener('click', () => exitAR());
document.querySelectorAll<HTMLButtonElement>('[data-move]').forEach(button => button.addEventListener('click', () => {
  if (arState !== 'adjusting') return;
  const direction = button.dataset.move;
  const delta = new Vector3(direction === 'left' ? -.3048 : direction === 'right' ? .3048 : 0, 0, direction === 'front' ? -.3048 : direction === 'rear' ? .3048 : 0);
  delta.applyAxisAngle(new Vector3(0,1,0), placement.rotation.y); placement.position.add(delta);
}));
document.addEventListener('visibilitychange', () => { if (document.hidden && tracking) exitAR('Camera paused. Start AR again to establish a new placement.'); });
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
    if (arState === 'preview') frameModel();
    syncARControls();
  } catch (error) { if (ticket === requestId) status.textContent = `Could not load the house. ${error instanceof Error ? error.message : 'Please retry.'}`; }
}
rotation.addEventListener('input', () => { placement.rotation.y = Number(rotation.value) * Math.PI / 180; document.querySelector('#angle')!.textContent = `${rotation.value}°`; });
elevation.addEventListener('input', () => { placement.position.y = Number(elevation.value) * .3048; document.querySelector('#height')!.textContent = `${elevation.value} ft`; });
document.querySelector('#reset')!.addEventListener('click', () => { rotation.value = '0'; elevation.value = '0'; rotation.dispatchEvent(new Event('input')); elevation.dispatchEvent(new Event('input')); frameModel(); });
document.querySelector('#display')!.addEventListener('click', event => { footprint = !footprint; if (model) model.visible = !footprint; (event.currentTarget as HTMLButtonElement).textContent = footprint ? 'Show house' : 'Footprint view'; status.textContent = footprint ? 'Bounding footprint and origin shown.' : 'House preview shown.'; });
const resize = new ResizeObserver(() => { const { width, height } = stage.getBoundingClientRect(); renderer.setSize(width, height); camera.aspect = width / height; camera.updateProjectionMatrix(); }); resize.observe(stage);
renderer.setAnimationLoop(() => { if (tracking && arState !== 'starting') { tracking.update(); renderer.render(scene, tracking.camera); } else { controls.update(); renderer.render(scene, camera); } });
window.addEventListener('pagehide', event => { if (event.persisted) return; renderer.setAnimationLoop(null); resize.disconnect(); controls.dispose(); if (model) disposeModel(model); outline.geometry.dispose(); outline.material.dispose(); pin.geometry.dispose(); pin.material.dispose(); grid.geometry.dispose(); if (Array.isArray(grid.material)) grid.material.forEach(material => material.dispose()); else grid.material.dispose(); renderer.dispose(); });
void selectHouse(houses[0].id);
