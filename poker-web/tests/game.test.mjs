import {test} from 'node:test';
import assert from 'node:assert/strict';
import {Deck,World,evaluate} from '../model.mjs';
const step=(w,n,input={})=>{for(let i=0;i<n;i++)w.step(1/60,input)};
const emptyWorld=()=>{let w=new World();w.enemies=[];return w};
test('all poker categories, wheel, partial and empty hands',()=>{
 const cases=[[[12,14,29,45,8],0,1],[[5,18,29,45,8],1,2],[[5,18,8,21,40],2,4],[[5,18,31,45,8],3,3],[[0,14,28,42,4],4,5],[[0,2,5,8,11],5,5],[[5,18,31,8,21],6,5],[[5,18,31,44,8],7,4],[[0,1,2,3,4],8,5],[[12,13,27,41,3],4,5]];
 for(const [cards,tier,count] of cases){const r=evaluate(cards);assert.equal(r.tier,tier);assert.equal(r.indices.length,count)}
 assert.equal(evaluate([]).damage,0);assert.equal(evaluate([5,18]).tier,1);assert.notEqual(evaluate([11,12,13,14,15]).tier,4);
});
test('draws bank, swap, refill and preserve 52 unique cards through reshuffles',()=>{
 const d=new Deck();assert.equal(d.hand.length,5);d.hit();d.hit();assert.equal(d.banked,false);const draft=d.hit();assert.equal(d.banked,false);d.choose(draft.id,0);assert.equal(d.banked,true);
 for(let i=0;i<8;i++)d.hit();assert.equal(d.hits,0);assert.equal(d.replace(-1),false);assert.equal(d.banked,true);assert.equal(d.replace(0),true);assert.equal(d.hand.length,5);
 d.preset([5,18,2,9,24]);d.play();assert.deepEqual(d.hand,[2,9,24]);d.hit();d.hit();const refill=d.hit();d.choose(refill.id,1);assert.equal(d.hand.length,4);
 for(let cycle=0;cycle<250;cycle++){d.play();for(let i=0;i<15;i++){const offer=d.hit();if(offer)d.choose(offer.id,cycle%2)}let all=[...d.hand,...d.pile,...d.discard,...d.drafts.flatMap(x=>x.cards),...(d.banked?[d.reserve]:[])];assert.equal(all.length,52);assert.equal(new Set(all).size,52);assert.ok(d.hand.length<=5)}
});
test('variable jump height, coyote time and buffered landing',()=>{
 let full=emptyWorld(),tap=emptyWorld();full.jump();tap.jump();tap.releaseJump();let fullMin=420,tapMin=420;
 for(let i=0;i<50;i++){step(full,1);step(tap,1);fullMin=Math.min(fullMin,full.y);tapMin=Math.min(tapMin,tap.y)}assert.ok(tapMin-fullMin>30);
 let w=emptyWorld();w.grounded=false;w.coyote=.08;w.jump();assert.equal(w.vy,-430);w.vy=100;w.coyote=0;w.buffer=0;w.jump();assert.equal(w.vy,100);
 w.x=80;w.y=419;w.vy=100;w.buffer=.1;step(w,1);assert.equal(w.vy,-430);
});
test('dash, drop-through, falling and pause',()=>{
 let w=emptyWorld();w.startDash();step(w,1);assert.equal(w.vx,570);assert.ok(w.invincible>0);let cd=w.dashCD;w.startDash();assert.equal(w.dashCD,cd);
 w=emptyWorld();w.x=220;w.y=360;w.surface=3;w.dropDown();step(w,40);assert.equal(w.y,420);
 w=emptyWorld();w.x=680;w.y=540;let hand=[...w.deck.hand];step(w,1);assert.equal(w.health,4);assert.equal(w.x,60);assert.deepEqual(w.deck.hand,hand);
 w.mode='paused';const x=w.x;step(w,30,{axis:1,sword:true});assert.equal(w.x,x);
});
test('sword earns draws but poker does not, rare hands transform and expire',()=>{
 let w=new World();w.practiceDeal(1);w.enemies.forEach(e=>e.hp=200);w.play();assert.equal(w.dark,6);assert.equal(w.deck.hand.length,0);step(w,40);
 for(const e of w.enemies)assert.equal(e.hp,160);assert.equal(w.deck.hits,0);
 w.enemies=[];w.spawn(w.x+40,0);let hp=w.enemies[0].hp;w.sword();step(w,7);assert.equal(w.enemies[0].hp,hp-4);assert.equal(w.deck.hits,1);
 w.enemies=[];step(w,400);assert.equal(w.dark,0);
 w.practiceDeal(2);w.enemies=[];w.spawn(w.x-70,0);w.spawn(w.x+70,0);w.play();assert.equal(w.kills,2);assert.equal(w.deck.hand.length,1);assert.equal(w.dark,6);
});
test('elevated attacks and swept projectile collisions',()=>{
 const w=new World();w.enemies=[];w.x=380;w.y=300;w.spawn(420,4);w.spawn(420,0);w.sword();step(w,7);assert.equal(w.enemies[0].hp,12);assert.equal(w.enemies[1].hp,14);
 w.deck.preset([5,18,2,9,24]);w.play();w.step(.2);assert.equal(w.enemies.length,1);assert.equal(w.enemies[0].y,420);
});
function travel(w,target,jump=false,dash=false){
 if(jump)w.jump();if(dash)w.startDash();
 for(let i=0;i<240;i++){const d=target-w.x;w.step(1/60,{axis:Math.abs(d)<1?0:Math.max(-1,Math.min(1,d/22))});if(Math.abs(d)<4&&Math.abs(w.vx)<10&&w.grounded)return;assert.equal(w.mode,'playing');}
 assert.fail('Failed to reach '+target+' from '+w.x+','+w.y);
}
test('complete authored route collects three embers and reaches lantern',()=>{
 const w=emptyWorld();
 travel(w,125);travel(w,220,true);assert.equal(w.y,360);
 travel(w,285);travel(w,405,true);assert.equal(w.y,300);assert.equal(w.collected,1);
 travel(w,465);travel(w,570,true);assert.equal(w.y,240);
 travel(w,790,true,true);assert.equal(w.y,420);
 travel(w,850);travel(w,940,true);assert.equal(w.y,360);
 travel(w,998);travel(w,1100,true);assert.equal(w.y,300);
 travel(w,1165);travel(w,1280,true);assert.equal(w.y,240);assert.equal(w.collected,2);
 travel(w,1345);travel(w,1620,true,true);assert.equal(w.y,420);
 travel(w,1640);travel(w,1730,true);assert.equal(w.y,360);
 travel(w,1788);travel(w,1910,true);assert.equal(w.y,300);
 travel(w,1968);travel(w,2090,true);assert.equal(w.y,240);assert.equal(w.collected,3);
 travel(w,2140);travel(w,2250,true);assert.equal(w.y,300);
 for(let i=0;i<120&&w.mode==='playing';i++)w.step(1/60,{axis:1});assert.equal(w.mode,'won');assert.equal(w.fallCount,0);
});
