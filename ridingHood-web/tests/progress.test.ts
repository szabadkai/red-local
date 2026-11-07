import { test } from 'node:test';
import assert from 'node:assert/strict';
import { freshProgress, parseProgress, recordCompletion, loadProgress, saveProgress, isRoomUnlocked, resumeRoomIndex } from '../src/prototype/progress.ts';
import { ROOMS } from '../src/prototype/rooms.ts';

test('completed rooms resume at the next stable room ID and survive reload', () => {
  const restored = parseProgress(JSON.stringify(recordCompletion(freshProgress(), ROOMS[0].id, true)));
  assert.equal(restored.currentRoom, ROOMS[1].id);
  assert.deepEqual(restored.completed, [ROOMS[0].id]);
  assert.deepEqual(restored.keepsakes, [ROOMS[0].id]);
  assert.equal(restored.started, true);
});

test('replays preserve collected keepsakes and completion is idempotent', () => {
  const first = recordCompletion(freshProgress(), ROOMS[0].id, true);
  assert.deepEqual(recordCompletion(first, ROOMS[0].id, false), first);
  assert.equal(recordCompletion(first, 'missing-room', true), first);
  assert.equal(recordCompletion(first, ROOMS.at(-1)!.id, false).currentRoom, ROOMS.at(-1)!.id);
});

test('damaged and future saves fall back safely; partial saves discard unknown IDs and duplicates', () => {
  for (const raw of [null, '{', 'null', '[]', '{"version":99}']) assert.deepEqual(parseProgress(raw), freshProgress());
  const progress = parseProgress(JSON.stringify({version:1, started:'yes', currentRoom:'removed',
    completed:[ROOMS[0].id, ROOMS[0].id, null, 'removed'], keepsakes:{}, muted:'false', transformations:false}));
  assert.equal(progress.currentRoom, ROOMS[0].id);
  assert.deepEqual(progress.completed, [ROOMS[0].id]);
  assert.deepEqual(progress.keepsakes, []);
  assert.equal(progress.muted, true);
  assert.equal(progress.transformations, false);
});

test('blocked storage permits play and reports an unsuccessful save', () => {
  const blocked = {getItem:()=>{throw new Error('blocked');},setItem:()=>{throw new Error('quota');}};
  assert.deepEqual(loadProgress(blocked), freshProgress());
  assert.equal(saveProgress(blocked, freshProgress()), false);
});

test('room IDs are unique and every room supplies progressive hints and a story beat', () => {
  assert.equal(new Set(ROOMS.map(room=>room.id)).size, ROOMS.length);
  assert.ok(ROOMS.every(room=>room.hints.length===3 && room.hints.every(Boolean) && room.memory));
});

test('preferences and mastery counts survive reload and invalid values are constrained',()=>{
  const source={...freshProgress(),musicVolume:.4,effectsVolume:.8,reducedMotion:true,assist:true,largeText:true};
  let saved=recordCompletion(source,ROOMS[0].id,true,2);
  saved=recordCompletion(saved,ROOMS[0].id,false,3);
  assert.equal(saved.bestCards[ROOMS[0].id],2);
  saved=recordCompletion(saved,ROOMS[0].id,false,1);
  assert.deepEqual(parseProgress(JSON.stringify(saved)),saved);
  const damaged=parseProgress(JSON.stringify({...saved,musicVolume:8,effectsVolume:-1,bestCards:{[ROOMS[0].id]:99,missing:0}}));
  assert.equal(damaged.musicVolume,1);assert.equal(damaged.effectsVolume,0);assert.deepEqual(damaged.bestCards,{});
});


test('campaign unlocks the next room and recovers old saves without skipping the journey',()=>{
  const fresh=freshProgress();assert.ok(isRoomUnlocked(fresh,0));assert.equal(isRoomUnlocked(fresh,1),false);assert.equal(isRoomUnlocked(fresh,-1),false);
  const first=recordCompletion(fresh,ROOMS[0].id,false);assert.ok(isRoomUnlocked(first,1));assert.equal(isRoomUnlocked(first,2),false);assert.equal(resumeRoomIndex(first),1);
  assert.equal(resumeRoomIndex({...first,currentRoom:ROOMS.at(-1)!.id}),1);
  const legacy={...fresh,completed:['lantern-keeper'],currentRoom:'lantern-keeper'};
  assert.equal(resumeRoomIndex(legacy),3);assert.ok(isRoomUnlocked(legacy,4));
});
