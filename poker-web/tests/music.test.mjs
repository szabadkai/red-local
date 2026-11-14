import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import '../chip.mjs';
import {STAGE_TUNES,BOSS_TUNES,tuneFor} from '../music.mjs';
import {StoryWorld} from '../story.mjs';
import {SFX} from '../sfx.mjs';

test('each stage and boss phase picks its own tune',()=>{
 const w=new StoryWorld();
 for(let stage=0;stage<5;stage++){
  w.reset(stage,{phase:'trail',seen:['prologue']});assert.equal(tuneFor(w),STAGE_TUNES[stage]);
  w.reset(stage,{phase:'boss',seen:['prologue']});assert.equal(tuneFor(w),BOSS_TUNES[stage]);
 }
 w.reset(4,{phase:'inside',seen:['prologue']});assert.equal(tuneFor(w),BOSS_TUNES[4]);
 w.reset(4,{phase:'garden',seen:['prologue']});assert.equal(tuneFor(w),BOSS_TUNES[4]);
 w.reset(4,{phase:'home',seen:['prologue']});assert.equal(tuneFor(w),STAGE_TUNES[0]);
});

test('every tune renders without bar-count warnings',async()=>{
 for(const name of [...STAGE_TUNES,...BOSS_TUNES]){
  const text=await readFile(new URL(`../assets/music/${name}.mml`,import.meta.url),'utf8');
  const {samples,warnings}=globalThis.Chip.render(text);
  assert.deepEqual(warnings,[],name);assert.ok(samples.length>globalThis.Chip.SR*20,name);
 }
});

test('every sound the game asks for is synthesised, short and audible',async()=>{
 const files=await Promise.all(['model.mjs','story.mjs','game.mjs'].map(f=>readFile(new URL('../'+f,import.meta.url),'utf8')));
 const asked=[...files.join('\n').matchAll(/(?:emit|sound)\('([a-z0-9_]+)'\)/g)].map(m=>m[1]);
 assert.ok(asked.length>10);
 for(const name of [...asked,'boss_intro','victory'])assert.ok(SFX[name],name);
 for(const [name,{text}] of Object.entries(SFX)){
  const {samples,warnings}=globalThis.Chip.render(text),seconds=samples.length/globalThis.Chip.SR;
  assert.deepEqual(warnings,[],name);assert.ok(seconds>.05&&seconds<2.5,`${name}: ${seconds}s`);
  assert.ok(samples.some(v=>Math.abs(v)>.5),name);
 }
});
