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
 assert.equal(row(deathFrame(.3,.6)),5);assert.equal(deathFrame(0,.6).x,7*32);
});
