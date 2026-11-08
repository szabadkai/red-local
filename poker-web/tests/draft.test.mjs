import {test} from 'node:test';
import assert from 'node:assert/strict';
import {World,Deck} from '../model.mjs';
const step=(w,n,input={})=>{for(let i=0;i<n;i++)w.step(1/60,input)};
const earn=d=>{d.hit();d.hit();return d.hit()};
const inventory=d=>[...d.hand,...d.pile,...d.discard,...d.drafts.flatMap(x=>x.cards),...(d.banked?[d.reserve]:[])];
function fixture(){const w=new World();w.practiceDeal(3);w.enemies=[];return w;}
test('three landed swings create one pickup without adding a random card',()=>{
 const w=new World();w.practiceDeal(0);w.enemies=[];w.spawn(220,0);w.enemies[0].hp=100;
 const hand=[...w.deck.hand];
 for(let i=0;i<3;i++){w.enemies[0].x=220;w.sword();step(w,20);}
 assert.equal(w.cardDrops.length,1);assert.equal(w.deck.drafts.length,1);assert.equal(w.deck.drafts[0].cards.length,2);
 assert.deepEqual(w.deck.hand,hand);assert.equal(w.deck.banked,false);assert.equal(w.mode,'playing');assert.equal(inventory(w.deck).length,52);
});
test('touching a pickup freezes the world; Escape preserves its exact choices and requires leaving',()=>{
 const w=fixture(),drop=w.cardDrops[0];w.x=drop.x;step(w,30);assert.equal(w.mode,'drafting');
 const choices=[...w.deck.drafts[0].cards],state={x:w.x,y:w.y,time:w.time,health:w.health,hand:[...w.deck.hand]};
 w.step(5,{axis:1,sword:true,play:true});assert.deepEqual({x:w.x,y:w.y,time:w.time,health:w.health,hand:w.deck.hand},state);
 w.dismissDraft();assert.equal(w.mode,'playing');assert.deepEqual(w.deck.drafts[0].cards,choices);assert.equal(w.cardDrops.length,1);
 step(w,40);assert.equal(w.mode,'playing');w.x=drop.x+50;step(w,1);w.x=drop.x;step(w,1);
 assert.equal(w.mode,'drafting');assert.deepEqual(w.deck.drafts[0].cards,choices);
});
test('choosing saves the exact card, including card zero, and replaces the requested slot',()=>{
 const d=new Deck();d.preset([5,18,2,9,24]);d.pile=d.pile.filter(c=>c!==0);d.pile.push(0);
 const offer=earn(d),other=offer.cards[1];assert.equal(offer.cards[0],0);
 assert.deepEqual(d.choose(offer.id,0),{card:0,banked:true});assert.equal(d.reserve,0);assert.ok(d.discard.includes(other));
 const old=d.hand[2];assert.equal(d.replace(2),true);assert.equal(d.hand[2],0);assert.ok(d.discard.includes(old));assert.equal(d.banked,false);
 assert.equal(inventory(d).length,52);assert.equal(new Set(inventory(d)).size,52);assert.equal(d.choose(offer.id,1),null);
});
test('choosing fills an empty slot; playing a hand spends the saved card into a slot',()=>{
 const w=fixture(),drop=w.cardDrops[0],chosen=w.deck.drafts[0].cards[1];w.play();w.cast=0;w.x=drop.x;step(w,30);
 assert.equal(w.mode,'drafting');const before=w.deck.hand.length;assert.equal(w.chooseDraft(1),true);
 assert.equal(w.mode,'playing');assert.equal(w.cardDrops.length,0);assert.equal(w.deck.hand.length,before+1);assert.ok(w.deck.hand.includes(chosen));
 const d=new Deck(),offer=earn(d);d.choose(offer.id,0);const saved=d.reserve;d.play();assert.equal(d.banked,false);assert.ok(d.hand.includes(saved));
});
test('queued pickups own distinct cards and skipping overlapping pickups resumes without a modal loop',()=>{
 const w=fixture(),drop=w.cardDrops[0];w.spawnCardDrop(earn(w.deck),{x:drop.x,y:drop.y});w.x=drop.x;step(w,30);
 w.dismissDraft();step(w,60);assert.equal(w.mode,'playing');assert.equal(w.cardDrops.length,2);
 assert.equal(new Set(inventory(w.deck)).size,52);assert.equal(inventory(w.deck).length,52);
 w.reset();assert.equal(w.cardDrops.length,0);assert.equal(w.deck.drafts.length,0);assert.equal(w.activeDraft,null);
});
test('drops land on reachable ground instead of inside a gap; a full reserve is never overwritten',()=>{
 const w=new World(),offer=earn(w.deck);w.spawnCardDrop(offer,{x:680,y:350});const drop=w.cardDrops[0];
 assert.ok(w.platforms.some(p=>p.y===drop.y&&drop.x>=p.x+18&&drop.x<=p.x+p.w-18));assert.ok(drop.y>=350);
 const second=earn(w.deck);w.deck.choose(second.id,0);const saved=w.deck.reserve;
 // Existing uncollected drafts cannot replace a saved choice until it is used.
 assert.equal(w.deck.hit(),null);assert.equal(w.deck.reserve,saved);assert.equal(w.openDraft(drop),false);assert.equal(w.deck.choose(offer.id,0),null);w.deck.replace(0);assert.equal(w.openDraft(drop),true);
});
