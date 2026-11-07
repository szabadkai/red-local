import { test } from 'node:test';
import assert from 'node:assert/strict';
import { World, ROOMS, BALANCE } from '../src/prototype/model.ts';
import { PadInput } from '../src/prototype/gamepad.ts';
function run(w:World,seconds:number,dir=0){for(let t=0;t<seconds;t+=BALANCE.step)w.step(BALANCE.step,dir);}
test('moving platforms carry riders, freeze during planning, and return to initial phase on retry',()=>{
  const w=new World(ROOMS.findIndex(r=>r.id==='millpond'));
  w.x=360;w.y=320;w.grounded=true;w.supportIndex=1;
  const offset=w.x-w.roomPlatforms[1].x;run(w,.5);
  assert.ok(Math.abs(w.x-w.roomPlatforms[1].x-offset)<.001);
  w.freeze();const before=JSON.stringify(w);run(w,3);assert.equal(JSON.stringify(w),before);
  w.retry();assert.equal(w.time,0);assert.equal(w.supportIndex,null);assert.equal(w.roomPlatforms[1].x,w.room.platforms[1].x);
});
test('crumbling ledges warn, freeze, disappear, and restore on retry',()=>{
  const w=new World(ROOMS.findIndex(r=>r.id==='courtyard'));
  w.x=380;w.y=319;w.vy=50;w.grounded=false;run(w,.1);
  assert.ok(w.events.includes('crack'));assert.equal(w.supportIndex,1);
  w.freeze();const before=JSON.stringify(w);run(w,5);assert.equal(JSON.stringify(w),before);
  w.cancel();run(w,1.55);assert.ok(!w.roomPlatforms.some(p=>p.sourceIndex===1));assert.ok(w.events.includes('crumble'));
  w.retry();assert.deepEqual(w.crumbleTimers,{});assert.ok(w.roomPlatforms.some(p=>p.sourceIndex===1));
});
test('gamepad input uses edges, ignores stick drift, and clears held buttons on disconnect',()=>{
  const input=new PadInput();const buttons=Array.from({length:16},()=>({pressed:false}));buttons[3].pressed=true;
  let sample=input.sample({buttons,axes:[.1,0,.8,-.7]});assert.deepEqual(sample.pressed,[3]);assert.equal(sample.direction,0);assert.equal(sample.aimX,.8);
  sample=input.sample({buttons,axes:[-.9,0,0,0]});assert.deepEqual(sample.pressed,[]);assert.equal(sample.direction,-1);
  sample=input.sample(null);assert.deepEqual(sample.released,[3]);assert.ok(sample.disconnected);assert.equal(sample.direction,0);
  assert.equal(input.sample(null).disconnected,false);
});

test('landing beyond a lantern completes the room without an awkward walk back',()=>{
  const w=new World();w.x=940;w.y=w.room.exit.y;w.grounded=true;
  w.step(BALANCE.step,0);assert.equal(w.mode,'complete');
});

test('a moving raft cannot carry a rider through the central pier',()=>{
  const w=new World(ROOMS.findIndex(r=>r.id==='ferry-crossing'));
  w.x=380;w.y=330;w.grounded=true;w.supportIndex=1;
  run(w,1.4);
  assert.ok(w.x<=396.01,`carried through solid pier: ${w.x}`);
  assert.equal(w.attempts,1);
});
