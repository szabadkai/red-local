import {ENEMY_TYPES} from './enemies.mjs';
// Little Red Riding Hood roster: 32x32 cells, one tag per sheet row, feet on the bottom row.
// Rows: idle(4) run(4) attack(6) special(8) hit(4) death(8). Facing right in the source.
export const CELL=32;
const ROW={idle:[0,4],run:[1,4],attack:[2,6],special:[3,8],hit:[4,4],death:[5,8]};
// Highest opaque source row across the action rows; keeps health bars and lines above the head.
export const CAST={
 big_bad_wolf:5,rogue_hunter:13,forest_witch:5,wild_boar:7,forest_crow:10,living_tree:7,thorn_brambles:7,
 lost_wisp:9,brown_bear:1,forest_stag:0,spore_mushroom:1,ghost_hunter:2,raven:0,will_o_wisp:3,
 wolf_in_disguise:12,mother:6,grandmother:9,woodcutter:6
};
export const castTop=skin=>CAST[skin]??0;
// Bow and crossbow skins shoot arrows (ranged 'mage' behaviour) and draw their bow on the attack row.
export const ARCHERS=new Set(['rogue_hunter','ghost_hunter']);
// Each clearing dresses its enemy behaviours in local wildlife; every roster enemy appears on the journey.
const DEFAULT={scout:['big_bad_wolf'],brute:['brown_bear'],runner:['wild_boar','forest_crow'],mage:['forest_witch','will_o_wisp'],guard:['living_tree','forest_stag']};
const THEMES={
 'lantern-wood':{scout:['big_bad_wolf'],mage:['rogue_hunter'],brute:['brown_bear'],runner:['wild_boar']},
 'broken-crossing':{guard:['forest_stag'],mage:['forest_witch'],runner:['forest_crow']},
 'moss-cavern':{runner:['raven','wild_boar'],mage:['spore_mushroom','lost_wisp'],guard:['living_tree']},
 'ruined-chapel':{guard:['thorn_brambles','living_tree'],mage:['ghost_hunter','will_o_wisp'],runner:['raven']},
 'thorn-house':{scout:['wolf_in_disguise'],runner:['wild_boar'],mage:['forest_witch','will_o_wisp'],guard:['brown_bear','thorn_brambles']}
};
export function skinFor(kind,clearingId,slot=0){
 const list=THEMES[clearingId]?.[kind]||DEFAULT[kind]||DEFAULT.scout;
 return list[slot%list.length];
}
function cell(tag,index){const [row,count]=ROW[tag];return {tag,x:(Math.max(0,index)%count)*CELL,y:row*CELL,w:CELL,h:CELL};}
// Maps the existing enemy state machine onto the roster tags.
export function castFrame(e,time){
 if((e.hurt||0)>0||e.state==='stagger'){const t=.32-(e.hurt||0);return cell('hit',t<.06?0:Math.min(3,1+Math.floor((t-.06)/.087)));}
 const archer=e.kind==='mage'&&ARCHERS.has(e.skin);
 if(e.state==='windup'){
  const total=(ENEMY_TYPES[e.kind]||ENEMY_TYPES.scout).wind,progress=1-Math.max(0,e.wind||0)/total;
  if(archer)return cell('attack',Math.min(2,Math.floor(progress*3)));
  return e.kind==='mage'?cell('special',Math.min(7,Math.floor(progress*8))):cell('attack',Math.min(2,Math.floor(progress*3)));
 }
 if(e.state==='lunge')return cell('attack',3+Math.min(2,Math.floor((.17-(e.action||0))/.06)));
 if(e.air)return cell('run',e.vy<0?1:3);
 if(archer&&e.state==='recover'){const since=ENEMY_TYPES.mage.recovery-(e.rest||0);if(since<.14)return cell('attack',3);if(since<.4)return cell('attack',5);}
 if(['chase','patrol','jump','drop'].includes(e.state))return cell('run',Math.floor((e.walk||0)*10+(e.id||0)));
 return cell('idle',Math.floor(time*5+(e.id||0)));
}
// Corpses play the death row once (90 ms a frame), then hold the last frame while they fade.
export const deathFrame=(life,duration)=>cell('death',Math.min(7,Math.floor((duration-life)/.09)));
export const idleFrame=(time,phase=0)=>cell('idle',Math.floor(time*5+phase));
