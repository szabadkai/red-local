import {test} from 'node:test';
import assert from 'node:assert/strict';
import {World} from '../model.mjs';
import {playerClip,playerFrame} from '../animation.mjs';
import {playerOffset} from '../art.mjs';
const step=(w,n,input={})=>{for(let i=0;i<n;i++)w.step(1/60,input)};
const darkWorld=()=>{const w=new World();w.practiceDeal(1);w.enemies=[];w.play();return w};
test('entering Dark Red uses Light-to-Dark; expiration uses Dark-to-Light',()=>{
 const w=darkWorld();assert.deepEqual(playerClip(w),{form:'light',state:'transform',facing:1});
 assert.equal(playerFrame('transform',w,0),0);step(w,46);
 assert.equal(playerClip(w).form,'dark');assert.equal(playerClip(w).state,'idle_blink');
 w.dark=.01;w.step(1/60);assert.equal(w.dark,0);assert.equal(w.morphFrom,'dark');
 assert.equal(playerClip(w).state,'transform');assert.equal(playerClip(w).form,'dark');
 step(w,37);assert.equal(playerClip(w).form,'light');assert.equal(playerClip(w).state,'idle_blink');
});
test('sword, dash and movement interrupt the body morph without suppressing their animation',()=>{
 for(const input of [{sword:true},{dash:true},{axis:1},{jump:true}]){
  const w=darkWorld();w.step(1/60,input);assert.equal(w.morphPose,false);assert.ok(w.transform>0);
  assert.notEqual(playerClip(w).state,'transform');
  if(input.sword)assert.equal(playerClip(w).state,'attack1');
  if(input.dash)assert.equal(playerClip(w).state,'dash');
  step(w,5);assert.equal(w.morphPose,false);
 }
});
test('refreshing an active dark form does not restart the morph',()=>{
 const w=darkWorld();step(w,50);w.deck.preset([0,2,5,8,11]);w.play();
 assert.equal(w.dark,6);assert.equal(w.transform,0);assert.equal(playerClip(w).state,'attack3');
});
test('attack stays in its starting form and direction through expiry; contact pose matches damage',()=>{
 const w=darkWorld();step(w,50);w.spawn(w.x+30,0);w.enemies[0].hp=100;w.dark=.05;w.sword();w.facing=-1;step(w,7);
 assert.equal(w.dark,0);assert.equal(playerClip(w).form,'dark');assert.equal(playerClip(w).facing,1);assert.equal(w.enemies[0].hp,96);
 assert.equal(playerFrame('attack1',w,0),1);step(w,14);assert.equal(playerClip(w).form,'light');
});
test('opaque sprite feet align across forms and airtime holds its final pose',()=>{
 assert.deepEqual(playerOffset('light','attack1',52,27),{x:-36,y:-54});
 assert.deepEqual(playerOffset('dark','attack1',65,39),{x:-52,y:-66});
 // Dark attack art has eight extra pixels on the left and six transparent rows below its feet.
 assert.equal(playerOffset('dark','attack1',65,39).x+8*2,-36);
 assert.equal(playerOffset('dark','attack1',65,39).y+33*2,0);
 assert.equal(playerOffset('light','transform',23,63).y+60*2,0);
 assert.equal(playerOffset('dark','transform',26,67).y+65*2,0);
 assert.equal(playerFrame('jump',{},3),3);assert.equal(playerFrame('fall',{},3),3);
});
