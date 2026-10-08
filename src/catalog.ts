export interface House {
  id: string;
  name: string;
  url?: string;
  color: string;
  dimensionsFeet: readonly [number, number, number];
  /** Rotation about Y to map the verified facade toward -Z. Pending visual verification. */
  frontRotation: number;
  originVerified: boolean;
}

export const houses: House[] = [
  { id: 'house-01', name: 'House 1', url: `${import.meta.env.BASE_URL}models/house2story.glb`, color: '#d6c3a0', dimensionsFeet: [50, 45, 27], frontRotation: 0, originVerified: false },
  { id: 'house-02', name: 'House 2', color: '#adc7b7', dimensionsFeet: [50, 45, 27], frontRotation: 0, originVerified: false },
  { id: 'house-03', name: 'House 3', color: '#b8c5dc', dimensionsFeet: [50, 45, 27], frontRotation: 0, originVerified: false },
];
