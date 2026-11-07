import { ROOMS } from './rooms.ts';

export const PROGRESS_KEY = 'red.journey.v1';
export type Progress = {
  version: 1;
  started: boolean;
  currentRoom: string;
  completed: string[];
  keepsakes: string[];
  muted: boolean;
  transformations: boolean;
  musicVolume: number;
  effectsVolume: number;
  reducedMotion: boolean;
  assist: boolean;
  largeText: boolean;
  bestCards: Record<string,number>;
};
export const freshProgress = (): Progress => ({
  version: 1, started: false, currentRoom: ROOMS[0].id,
  completed: [], keepsakes: [], muted: true, transformations: true,
  musicVolume: .35, effectsVolume: .65, reducedMotion: false, assist: false, largeText: false, bestCards: {},
});
const knownRoom = (id: unknown): id is string => typeof id === 'string' && ROOMS.some(room => room.id === id);

export function isRoomUnlocked(progress: Progress, index: number): boolean {
  return index >= 0 && index < ROOMS.length && (index === 0 ||
    progress.completed.includes(ROOMS[index].id) || progress.completed.includes(ROOMS[index - 1].id));
}

export function resumeRoomIndex(progress: Progress): number {
  const saved = ROOMS.findIndex(room => room.id === progress.currentRoom);
  if (isRoomUnlocked(progress, saved)) return saved;
  const next = ROOMS.findIndex((room, index) => isRoomUnlocked(progress, index) && !progress.completed.includes(room.id));
  return Math.max(0, next);
}

export function parseProgress(raw: string | null): Progress {
  const progress = freshProgress();
  try {
    const saved = JSON.parse(raw ?? 'null');
    if (!saved || saved.version !== 1) return progress;
    if (knownRoom(saved.currentRoom)) progress.currentRoom = saved.currentRoom;
    for (const field of ['completed', 'keepsakes'] as const) {
      if (Array.isArray(saved[field])) progress[field] = [...new Set<string>(saved[field].filter(knownRoom))];
    }
    progress.started = saved.started === true || progress.completed.length > 0;
    for(const field of ['musicVolume','effectsVolume'] as const)if(typeof saved[field]==='number'&&Number.isFinite(saved[field]))progress[field]=Math.max(0,Math.min(1,saved[field]));
    for(const field of ['reducedMotion','assist','largeText'] as const)if(typeof saved[field]==='boolean')progress[field]=saved[field];
    if(saved.bestCards && typeof saved.bestCards==='object')for(const [id,count] of Object.entries(saved.bestCards))if(knownRoom(id)&&typeof count==='number'&&Number.isInteger(count)&&count>=0&&count<=3)progress.bestCards[id]=count;
    if (typeof saved.muted === 'boolean') progress.muted = saved.muted;
    if (typeof saved.transformations === 'boolean') progress.transformations = saved.transformations;
  } catch { /* A damaged save should never prevent playing. */ }
  return progress;
}

export function recordCompletion(progress: Progress, roomId: string, keepsake: boolean, cardsUsed = 3): Progress {
  if (!knownRoom(roomId)) return progress;
  const index = ROOMS.findIndex(room => room.id === roomId);
  return {
    ...progress, started: true,
    bestCards: {...progress.bestCards,[roomId]:Math.min(progress.bestCards[roomId]??3,Math.max(0,Math.min(3,cardsUsed)))},
    currentRoom: ROOMS[Math.min(index + 1, ROOMS.length - 1)].id,
    completed: [...new Set([...progress.completed, roomId])],
    keepsakes: keepsake ? [...new Set([...progress.keepsakes, roomId])] : [...progress.keepsakes],
  };
}

export interface SaveStorage { getItem(key: string): string | null; setItem(key: string, value: string): void }
export function loadProgress(storage: SaveStorage): Progress {
  try { return parseProgress(storage.getItem(PROGRESS_KEY)); } catch { return freshProgress(); }
}
export function saveProgress(storage: SaveStorage, progress: Progress): boolean {
  try { storage.setItem(PROGRESS_KEY, JSON.stringify(progress)); return true; } catch { return false; }
}
