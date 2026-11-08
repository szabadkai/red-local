import {test} from 'node:test';
import assert from 'node:assert/strict';
import {World} from '../model.mjs';
import {updateEnemyShots} from '../enemies.mjs';
const setup=()=>{const w=new World();w.practiceDeal(5);w.enemies=[];return w};
test('hostile shots collide with Red, expire, and respect dash invulnerability',()=>{
 const w=setup();w.enemyShots=[{x:w.x+30,y:w.y-22,vx:-220,vy:0,life:2}];updateEnemyShots(w,.2);assert.equal(w.health,4);assert.equal(w.enemyShots.length,0);
 w.invincible=1;w.enemyShots=[{x:w.x+30,y:w.y-22,vx:-220,vy:0,life:2}];updateEnemyShots(w,.2);assert.equal(w.health,4);
 w.enemyShots=[{x:600,y:100,vx:0,vy:0,life:.01}];updateEnemyShots(w,.1);assert.equal(w.enemyShots.length,0);
});
test('sword can cut a hostile shot without farming draw credit',()=>{
 const w=setup();w.facing=1;w.enemyShots=[{x:w.x+60,y:w.y-22,vx:0,vy:0,life:2}];w.sword();for(let i=0;i<8;i++)w.step(1/60);
 assert.equal(w.enemyShots.length,0);assert.equal(w.deck.hits,0);assert.equal(w.health,5);
});
test('card choice and pause freeze hostile shots; retry clears them',()=>{
 const w=setup();w.enemyShots=[{x:600,y:100,vx:-220,vy:0,life:2}];
 for(const mode of ['paused','drafting']){w.mode=mode;const before=structuredClone(w.enemyShots);w.step(.5);assert.deepEqual(w.enemyShots,before);}
 w.retry();assert.equal(w.enemyShots.length,0);
});
