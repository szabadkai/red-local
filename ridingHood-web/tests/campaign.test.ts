import { test } from 'node:test';
import assert from 'node:assert/strict';
import { World, BALANCE, ROOMS, type Card } from '../src/prototype/model.ts';
function run(w:World,seconds:number,dir=0){for(let t=0;t<seconds;t+=BALANCE.step)w.step(BALANCE.step,dir);}
function walk(w:World,x:number){let n=0;while(Math.abs(w.x-x)>2&&n++<1200&&w.mode==='playing')w.step(BALANCE.step,w.x<x?1:-1);assert.ok(n<1200,`walk ${x}: ${w.x},${w.y}, attempt ${w.attempts}`);}
function card(w:World,c:Card,target?:{x:number;y:number}){assert.ok(w.select(c));if(target)w.target=target;assert.ok(w.confirm(),w.notice);}
function leap(w:World,seconds:number){w.jump();run(w,seconds,1);}
function treasure(w:World,x:number){walk(w,x);w.jump();run(w,.7);assert.ok(w.treasure,`missed treasure ${w.x},${w.y}`);}
function finish(w:World){walk(w,w.room.exit.x);assert.equal(w.mode,'complete',`${w.room.id}: ${w.x},${w.y}`);assert.equal(w.attempts,1);assert.ok(w.treasure);}
function dashExit(w:World,edge:number){walk(w,edge);leap(w,.2);card(w,'step');run(w,.85,1);finish(w);}
const routes: Record<string,(w:World)=>void>={
  'briar-garden':w=>{walk(w,220);leap(w,.2);card(w,'feather');run(w,1.2,1);treasure(w,500);dashExit(w,540);},
  'millpond':w=>{walk(w,230);leap(w,.2);card(w,'feather');run(w,1.1,1);card(w,'step');run(w,.7,1);finish(w);},
  'bell-tower':w=>{walk(w,190);leap(w,.55);walk(w,290);card(w,'feather');run(w,1.15,1);treasure(w,530);dashExit(w,630);},
  'lost-street':w=>{walk(w,235);leap(w,.2);card(w,'feather');run(w,1.15,1);treasure(w,530);dashExit(w,580);},
  'ferry-crossing':w=>{walk(w,205);leap(w,.2);card(w,'feather');run(w,1.2,1);treasure(w,475);dashExit(w,535);},
  'courtyard':w=>{walk(w,230);leap(w,.65);walk(w,410);leap(w,.65);treasure(w,530);dashExit(w,615);},
  'glasshouse':w=>{walk(w,240);leap(w,.2);card(w,'feather');run(w,1.15,1);treasure(w,490);dashExit(w,570);},
  'rooftops':w=>{walk(w,230);leap(w,.2);card(w,'feather');run(w,1.2,1);treasure(w,505);dashExit(w,570);},
  'hearth':w=>{walk(w,225);leap(w,.65);card(w,'feather');run(w,1.15,1);treasure(w,530);dashExit(w,605);},
};
for(const [id,route] of Object.entries(routes))test(`${id}: exit and keepsake through ordinary movement in one attempt`,()=>{
  const w=new World(ROOMS.findIndex(room=>room.id===id));route(w);
});

function briarExit(w:World,edge:number,target:{x:number;y:number}){
  walk(w,edge);card(w,'briar',target);leap(w,.6);run(w,.3);
  assert.equal(w.grounded,true,`Briar landing ${w.x},${w.y}`);
  walk(w,target.x+40);leap(w,1);finish(w);assert.ok(w.cards.step);
}
for(const [id,launch,seconds,tx,edge,bx,by] of [
  ['briar-garden',220,1.2,500,540,630,295],
  ['lost-street',235,1.15,530,580,675,260],
  ['ferry-crossing',205,1.2,475,535,665,280],
  ['glasshouse',240,1.15,490,570,690,250],
  ['rooftops',230,1.2,505,570,690,250],
] as const)test(`${id}: Briar substitutes for Step on the keepsake route`,()=>{
  const w=new World(ROOMS.findIndex(r=>r.id===id));walk(w,launch);leap(w,.2);card(w,'feather');run(w,seconds,1);treasure(w,tx);briarExit(w,edge,{x:bx,y:by});
});

test('millpond: ride the raft, collect the keepsake, and reach the exit without Feather or Briar',()=>{
  const w=new World(ROOMS.findIndex(r=>r.id==='millpond'));
  walk(w,230);run(w,3.3-w.time);leap(w,.55);run(w,.35);
  assert.equal(w.supportIndex,1);
  run(w,8.3-w.time);w.jump();run(w,.7);
  assert.ok(w.treasure,`raft keepsake: ${w.x},${w.y}`);
  leap(w,.2);card(w,'step');run(w,.8,1);finish(w);
  assert.ok(w.cards.feather&&w.cards.briar);
});

test('briar garden: learn placement before the middle island and keep Feather unused',()=>{
  const w=new World(ROOMS.findIndex(r=>r.id==='briar-garden'));
  walk(w,220);card(w,'briar',{x:340,y:310});leap(w,.65);walk(w,380);leap(w,.6);
  treasure(w,500);dashExit(w,540);assert.ok(w.cards.feather);
});
