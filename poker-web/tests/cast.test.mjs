import test from 'node:test';
import assert from 'node:assert/strict';
import {existsSync} from 'node:fs';
import {CAST,castFrame,deathFrame} from '../cast.mjs';
import {World} from '../model.mjs';
import {CLEARINGS} from '../journey.mjs';

test('every roster sheet is bundled', () => {
 for(const name of Object.keys(CAST))assert.ok(existsSync(new URL(`../assets/cast/${name}_sheet.png`,import.meta.url)),name);
});
test('the journey dresses enemies in the whole roster and places the townsfolk', () => {
 const seen=new Set(),npcs=new Set();
 CLEARINGS.forEach((_,i)=>{const w=new World();w.reset(i);for(const e of w.enemies){assert.ok(e.skin in CAST,e.skin);seen.add(e.skin)}for(const n of w.npcs)npcs.add(n.skin)});
 for(const name of ['big_bad_wolf','rogue_hunter','forest_witch','wild_boar','forest_crow','living_tree','thorn_brambles','lost_wisp','brown_bear','forest_stag','spore_mushroom','ghost_hunter','raven','will_o_wisp','wolf_in_disguise'])assert.ok(seen.has(name),name);
 assert.deepEqual([...npcs].sort(),['grandmother','mother','woodcutter']);
});
test('enemy states map onto the roster rows', () => {
 const row=f=>f.y/32,base={id:0,kind:'scout',walk:0,flash:0,air:false};
 assert.equal(row(castFrame({...base,state:'idle'},0)),0);
 assert.equal(row(castFrame({...base,state:'chase'},0)),1);
 assert.equal(row(castFrame({...base,state:'windup',wind:.2},0)),2);
 assert.equal(row(castFrame({...base,kind:'mage',state:'windup',wind:.4},0)),3);
 assert.equal(row(castFrame({...base,state:'stagger',flash:.1},0)),4);
 assert.equal(row(deathFrame(.3,1.2)),5);assert.equal(deathFrame(1.2,1.2).x,0);assert.equal(deathFrame(.4,1.2).x,7*32);
});
test('bowmen shoot arrows instead of swinging their bow', () => {
 const w=new World();w.reset(0);w.enemies=[];w.spawn(330,0,'mage');
 const e=w.enemies[0];assert.equal(e.skin,'rogue_hunter');assert.equal(e.arrow,true);
 w.x=180;w.y=420;for(let i=0;i<120&&!w.enemyShots.length;i++)w.step(1/60,{});
 assert.equal(w.enemyShots[0]?.arrow,true);
 assert.equal(castFrame({...e,state:'windup',wind:.4},0).y/32,2);
});
test('getting hit knocks Red away from the attacker and briefly takes control', () => {
 const w=new World();w.reset(0);w.enemies=[];w.x=500;w.y=420;w.grounded=true;w.facing=1;
 w.hurt(560);assert.equal(w.health,4);assert.ok(w.vx<0&&w.vy<0);assert.ok(w.knock>0);
 const x=w.x;for(let i=0;i<10;i++)w.step(1/60,{axis:1});assert.ok(w.x<x,'input cannot cancel the knockback');
 for(let i=0;i<40;i++)w.step(1/60,{axis:1});assert.ok(w.knock===0&&w.vx>0,'control returns');
});
test('enemy hit pose lasts long enough to read', () => {
 const w=new World();w.reset(0);w.enemies=[];w.spawn(600,0,'scout');const e=w.enemies[0];
 w.damage(e,1,0);const seen=new Set();
 for(let i=0;i<18;i++){const f=castFrame(e,0);if(f.y===4*32)seen.add(f.x);w.step(1/60,{});}
 assert.ok(seen.size>=3,'several hit frames are shown');
});
test('boss hit tests use the drawn body, not the centre point', async () => {
 const {StoryWorld}=await import('../story.mjs');
 const w=new StoryWorld();w.practiceDeal(10);const b=w.boss;b.x=600;b.y=420;b.state='recover';b.timer=5;
 w.x=512;w.y=420;w.attackFacing=1;w.attackForm='light';const hp=b.hp;w.resolveSword();
 assert.ok(b.hp<hp,'a sword swing reaching the Hart flank hits even with its centre out of reach');
});
test('the chain sweep only hurts where the chain has passed', async () => {
 const {StoryWorld}=await import('../story.mjs');
 const w=new StoryWorld();w.practiceDeal(11);const b=w.boss;b.x=600;b.y=420;b.face=1;b.strikeDir=1;
 b.state='strike';b.pattern='chain';b.duration=.4;b.elapsed=0;b.chainTip=null;w.x=420;w.y=420;w.invincible=0;
 const {updateBoss}=await import('../bosses.mjs');
 updateBoss(w,.05);assert.equal(w.health,5,'the tip starts in front of him, far from Red behind');
 for(let i=0;i<8;i++)updateBoss(w,.05);assert.equal(w.health,4,'the sweep reaches Red behind him');
});
