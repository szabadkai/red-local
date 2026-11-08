import {updateEnemies,updateEnemyShots,ENEMY_TYPES} from './enemies.mjs';
import {CLEARINGS,platformsFor} from './journey.mjs';
export const HANDS=['High card','Pair','Two pair','Three of a kind','Straight','Flush','Full house','Four of a kind','Straight flush'];
export const DAMAGE=[6,14,20,26,32,40,52,64,90];
export const EFFECTS=['Quick bolt','Heavy bolt','Explosive shot','Piercing lance','Piercing beam','Dark wave','Twin dark waves','Royal burst','Royal burst + wave'];
export const SUITS=['spades','diamonds','clubs','hearts'];
export function cardName(id){const rank=id%13+2;return `${({11:'Jack',12:'Queen',13:'King',14:'Ace'})[rank]||rank} of ${SUITS[Math.floor(id/13)]}`;}
export function evaluate(cards){
 if(!cards.length)return {tier:-1,name:'Empty hand',damage:0,indices:[]};
 const groups=new Map();cards.forEach((c,i)=>{let r=c%13+2;if(!groups.has(r))groups.set(r,[]);groups.get(r).push(i)});
 const ranks=[...groups.keys()].sort((a,b)=>groups.get(b).length-groups.get(a).length||b-a);
 const sorted=[...ranks].sort((a,b)=>a-b),count=groups.get(ranks[0]).length;
 const flush=cards.length===5&&cards.every(c=>Math.floor(c/13)===Math.floor(cards[0]/13));
 const straight=sorted.length===5&&(sorted[4]-sorted[0]===4||sorted.join(',')==='2,3,4,5,14');
 let tier=0,indices=[groups.get(ranks[0])[0]];
 if(straight&&flush)tier=8;
 else if(count===4){tier=7;indices=[...groups.get(ranks[0])]}
 else if(count===3&&groups.get(ranks[1])?.length===2)tier=6;
 else if(flush)tier=5;else if(straight)tier=4;
 else if(count===3){tier=3;indices=[...groups.get(ranks[0])]}
 else if(count===2){tier=1;indices=[...groups.get(ranks[0])];if(groups.get(ranks[1])?.length===2){tier=2;indices.push(...groups.get(ranks[1]))}}
 if([4,5,6,8].includes(tier))indices=cards.map((_,i)=>i);
 return {tier,name:HANDS[tier],damage:DAMAGE[tier],indices};
}
export class Deck{
 constructor(random=Math.random){this.random=random;this.reset()}
 shuffle(a){for(let i=a.length-1;i>0;i--){let j=Math.floor(this.random()*(i+1));[a[i],a[j]]=[a[j],a[i]]}return a}
 reset(){this.hand=[];this.pile=this.shuffle(Array.from({length:52},(_,i)=>i));this.discard=[];this.hits=0;this.reserve=null;this.drafts=[];this.nextDraft=0;for(let i=0;i<5;i++)this.draw()}
 get banked(){return this.reserve!==null}
 take(){if(!this.pile.length)this.pile=this.shuffle(this.discard.splice(0));return this.pile.pop()}
 draw(){if(this.hand.length>=5)return;const card=this.take();if(card!==undefined)this.hand.push(card)}
 hit(){
  if(this.banked)return null;this.hits=Math.min(3,this.hits+1);if(this.hits<3)return null;
  const a=this.take(),b=this.take();
  if(a===undefined||b===undefined){if(a!==undefined)this.pile.push(a);return null;}
  const draft={id:this.nextDraft++,cards:[a,b]};this.drafts.push(draft);this.hits=0;return draft;
 }
 choose(id,index){
  const draft=this.drafts.find(d=>d.id===id);if(!draft||![0,1].includes(index)||(this.hand.length===5&&this.banked))return null;
  const card=draft.cards[index];this.discard.push(draft.cards[1-index]);this.drafts=this.drafts.filter(d=>d.id!==id);
  if(this.hand.length<5)this.hand.push(card);else this.reserve=card;
  return {card,banked:this.banked};
 }
 play(){let r=evaluate(this.hand);for(let i of [...r.indices].sort((a,b)=>b-a))this.discard.push(...this.hand.splice(i,1));if(this.banked&&this.hand.length<5){this.hand.push(this.reserve);this.reserve=null}return r}
 replace(i){if(!this.banked||i<0||i>=this.hand.length)return false;this.discard.push(this.hand[i]);this.hand[i]=this.reserve;this.reserve=null;return true}
 preset(cards){this.hand=[...cards];this.pile=this.shuffle(Array.from({length:52},(_,i)=>i).filter(c=>!cards.includes(c)));this.discard=[];this.hits=0;this.reserve=null;this.drafts=[];this.nextDraft=0}
}
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const approach=(a,b,n)=>a<b?Math.min(a+n,b):Math.max(a-n,b);
export const WIDTH=2400;
export function level(){return platformsFor(0)}
export class World{
 constructor(random=Math.random){this.deck=new Deck(random);this.reset()}
 reset(stageIndex=0){
  this.stageIndex=stageIndex;this.clearing=CLEARINGS[stageIndex];this.arena=false;
  this.deck.reset();this.x=60;this.y=420;this.vx=0;this.vy=0;this.facing=1;this.grounded=true;this.surface=0;
  this.coyote=.12;this.buffer=0;this.drop=0;this.health=5;this.invincible=0;this.dash=0;this.dashCD=0;
  this.attack=0;this.swordPending=0;this.attackFacing=1;this.cast=0;this.dark=0;this.transform=0;this.land=0;this.time=0;this.fallCount=0;
  this.attackForm='light';this.castForm='light';this.castFacing=1;
  this.morphFrom='light';this.morphDuration=.75;this.morphPose=false;this.morphFacing=1;
  this.hitStop=0;this.shakeTime=0;this.shakeDuration=0;this.shakePower=0;
  this.cardDrops=[];this.activeDraft=null;this.lastPicked=null;
  this.platforms=platformsFor(stageIndex);this.embers=this.clearing.embers.map(([x,y])=>({x,y}));this.collected=0;
  this.checkpoint={x:60,y:420};this.checkpointId=0;this.mode='playing';this.practice=false;this.kills=0;
  this.impacts=[];this.corpses=[];this.bolts=[];this.enemyShots=[];this.rings=[];this.texts=[];this.particles=[];this.events=[];this.banner='';this.bannerTime=0;this.nextId=0;
  this.enemies=[];
  for(const [x,s,t] of this.clearing.enemies)this.spawn(x,s,t||false);
 }
 advance(){
  if(this.mode!=='won'||this.practice||this.stageIndex>=CLEARINGS.length-1)return false;
  this.reset(this.stageIndex+1);this.banner=this.clearing.name.toUpperCase();this.bannerTime=2.8;return true;
 }
 retry(){this.reset(this.stageIndex);}
 spawn(x,s,type=false){const platform=this.platforms[s];if(!platform)return;const kind=typeof type==='string'?type:type?'brute':'scout',def=ENEMY_TYPES[kind];if(!def)return;const tough=kind==='brute'||kind==='guard';this.enemies.push({id:this.nextId++,kind,x,y:platform.y,left:platform.x+16,right:platform.x+platform.w-16,hp:def.hp,max:def.hp,tough,wind:0,rest:.3,flash:0,walk:0,face:-1,state:'patrol',surface:s,patrolDir:this.nextId%2?1:-1,air:false,airVX:0,vy:0,hopCD:0,action:0,strikeDir:-1,connected:false})}
 practiceDeal(kind){if(kind>=7){this.reset(kind===9?1:kind===7?2:3);this.practice=true;this.banner='EXPLORE · '+this.clearing.name.toUpperCase();this.bannerTime=3;return;}this.reset();this.practice=true;this.arena=true;this.platforms=[{id:0,x:0,y:420,w:2400,ground:true}];this.embers=[];this.x=180;this.enemies=[];this.deck.preset([[5,18,2,9,24],[0,2,5,8,11],[5,18,31,44,8]][kind]||[5,18,2,9,24]);for(let i=0;i<3;i++)this.spawn(300+i*100,0,i===2);this.banner='PRACTICE · '+evaluate(this.deck.hand).name;this.bannerTime=2;if(kind===3){this.deck.pile=this.deck.pile.filter(c=>c!==31&&c!==12);this.deck.pile.push(12,31);this.deck.hit();this.deck.hit();this.spawnCardDrop(this.deck.hit(),{x:240,y:420});this.banner='TOUCH THE CARD · CHOOSE YOUR DRAW'}if(kind>=4){this.enemies=[];this.spawn(330,0,['runner','mage','guard'][kind-4]);this.banner=['GOBLIN RUNNER · DODGE THE LUNGE','LANTERN MAGE · JUMP OR SLASH ITS SHOT','IRON GUARD · BAIT THE SLAM'][kind-4];this.bannerTime=4;}}
 emit(type){this.events.push(type)}
 jump(){this.buffer=.14;this.tryJump()}
 tryJump(){if(this.buffer>0&&(this.grounded||this.coyote>0)){this.vy=-430;this.grounded=false;this.coyote=0;this.buffer=0;this.emit('jump')}}
 releaseJump(){if(this.vy < -170)this.vy=-170}
 dropDown(){if(this.grounded&&!this.platforms.find(p=>p.id===this.surface)?.ground){this.drop=.22;this.y+=3;this.grounded=false;this.coyote=0}}
 startDash(){if(this.dashCD>0||this.mode!=='playing')return;this.dash=.14;this.dashCD=.7;this.vy=0;this.invincible=Math.max(this.invincible,.14);this.emit('dash')}
 sword(){if(this.attack>0||this.mode!=='playing')return;this.attack=.32;this.swordPending=.10;this.attackFacing=this.facing;this.attackForm=this.dark>0?'dark':'light';this.morphPose=false;this.emit('attack1');}
 resolveSword(){let source=null;
  this.enemyShots=this.enemyShots.filter(b=>{const d=(b.x-this.x)*this.attackFacing;if(d>=-10&&d<76&&Math.abs(b.y-(this.y-22))<36){this.impacts.push({x:b.x,y:b.y,amount:2,life:.25});this.emit('attack3');return false;}return true;});
  for(const e of this.enemies){let d=(e.x-this.x)*this.attackFacing;if(d>=-10&&d<76&&Math.abs(e.y-this.y)<40){this.damage(e,this.attackForm==='dark'?4:2,10*this.attackFacing);source??={x:e.x,y:e.y}}}
  if(source){const draft=this.deck.hit();if(draft){this.spawnCardDrop(draft,source);this.emit('meter_full');this.banner='CARD DROP · TOUCH TO CHOOSE';this.bannerTime=1.5}}this.removeDead();
 }
 spawnCardDrop(draft,source){
  if(!draft)return;
  const below=this.platforms.filter(p=>p.y>=source.y-2&&source.x>=p.x&&source.x<=p.x+p.w);
  const lower=this.platforms.filter(p=>p.y>=source.y-2),candidates=below.length?below:lower.length?lower:this.platforms;
  const p=[...candidates].sort((a,b)=>{
   const score=p=>Math.abs(clamp(source.x,p.x+18,p.x+p.w-18)-source.x)*2+Math.abs(p.y-source.y);
   return score(a)-score(b);
  })[0];
  const x=clamp(source.x,p.x+18,p.x+p.w-18),y=p.y;
  this.cardDrops.push({id:draft.id,x,y,age:0,blocked:Math.abs(x-this.x)<28&&Math.abs(y-this.y)<30});
 }
 openDraft(drop){
  if(this.mode!=='playing'||(this.deck.banked&&this.deck.hand.length===5))return false;
  if(!this.deck.drafts.some(d=>d.id===drop.id))return false;
  this.activeDraft=drop.id;this.mode='drafting';return true;
 }
 chooseDraft(index){
  if(this.mode!=='drafting')return false;
  const result=this.deck.choose(this.activeDraft,index);if(!result)return false;
  const drop=this.cardDrops.find(d=>d.id===this.activeDraft);
  this.lastPicked={card:result.card,x:drop.x,y:drop.y-26};
  this.cardDrops=this.cardDrops.filter(d=>d.id!==this.activeDraft);this.activeDraft=null;this.mode='playing';
  this.suppressNearbyDrops();
  this.emit('pickup_essence');this.banner=(result.banked?'SAVED: ':'DREW: ')+cardName(result.card).toUpperCase();this.bannerTime=1.8;return true;
 }
 dismissDraft(){
  if(this.mode!=='drafting')return;
  this.suppressNearbyDrops();
  this.activeDraft=null;this.mode='playing';
 }
 suppressNearbyDrops(){for(const drop of this.cardDrops)if(Math.abs(drop.x-this.x)<32&&Math.abs(drop.y-this.y)<40)drop.blocked=true;}
 play(){if(this.cast>0||!this.deck.hand.length||this.mode!=='playing')return;const r=this.deck.play();this.cast=.36;this.banner=r.name.toUpperCase();this.bannerTime=1.5;this.emit('attack3');
  if(r.tier>=5){if(this.dark<=0)this.startMorph('light',.75);this.dark=6;this.invincible=Math.max(this.invincible,.75);this.emit('transform_dark')}
  this.castForm=this.dark>0?'dark':'light';this.castFacing=this.facing;
  const impact={tier:r.tier,spent:false};
  if(r.tier>=7)this.blast(this.x,this.y-22,270,r.damage,true,impact);
  if(r.tier<7||r.tier===8)this.fire(r,this.facing,impact);
  if(r.tier===6)this.fire(r,-this.facing,impact);this.removeDead();
 }
 startMorph(from,duration){this.morphFrom=from;this.morphDuration=duration;this.transform=duration;this.morphFacing=this.facing;this.morphPose=this.grounded&&Math.abs(this.vx)<=10&&this.attack<=0&&this.dash<=0;}
 pokerImpact(impact,killed=false){
  if(!impact||impact.spent||impact.tier<1)return;impact.spent=true;
  // One pulse per played hand, shared by piercing hits, explosions and twin waves.
  const frames=impact.tier>=7?5:impact.tier>=5?4:impact.tier>=2?3:2;
  this.hitStop=Math.max(this.hitStop,frames/60);
  this.shakePower=frames*2-2;this.shakeDuration=.1+frames*.025;this.shakeTime=this.shakeDuration;
 }
 fire(r,dir,impact){this.bolts.push({x:this.x+dir*20,y:this.y-23,dir,damage:r.damage,tier:r.tier,life:1.5,hit:new Set(),impact})}
 blast(x,y,radius,damage,dark=false,impact=null){this.rings.push({x,y,radius,dark,life:.45});for(const e of this.enemies)if(Math.hypot(e.x-x,e.y-22-y)<=radius){this.damage(e,damage,Math.sign(e.x-x)*40);this.pokerImpact(impact,e.hp<=0)}}
 damage(e,amount,push){e.hp-=amount;e.x=clamp(e.x+push,e.left,e.right);e.wind=0;e.rest=.22;e.flash=.15;e.state='stagger';this.texts.push({x:e.x,y:e.y-55,text:String(amount),life:.7});this.impacts.push({x:e.x,y:e.y-25,amount,life:.25,knockout:e.hp<=0});
  for(let i=0;i<7;i++)this.particles.push({x:e.x,y:e.y-22,vx:Math.cos(i*2.4)*90,vy:-40-i*12,life:.4});}
 removeDead(){for(const e of this.enemies)if(e.hp<=0)this.corpses.push({kind:e.kind,x:e.x,y:e.y,face:e.face,life:.32});this.kills+=this.enemies.filter(e=>e.hp<=0).length;this.enemies=this.enemies.filter(e=>e.hp>0)}
 hurt(){if(this.invincible>0)return;this.health--;this.invincible=1;this.emit('player_hurt');if(this.health<=0)this.mode='dead'}
 step(dt,input={}){
  if(this.mode!=='playing')return;
  this.shakeTime=Math.max(0,this.shakeTime-dt);
  if(this.hitStop>0){this.hitStop=Math.max(0,this.hitStop-dt-1e-9);return;}
  this.time+=dt;const wasDark=this.dark>0;
  for(const key of ['invincible','dash','dashCD','attack','cast','dark','transform','land','drop','buffer','bannerTime'])this[key]=Math.max(0,this[key]-dt);
  if(wasDark&&this.dark===0)this.startMorph('dark',.6);
  if(input.jump)this.jump();if(input.jumpRelease)this.releaseJump();if(input.drop)this.dropDown();if(input.dash)this.startDash();
  const axis=clamp(input.axis||0,-1,1);if(axis)this.facing=axis>0?1:-1;
  this.vx=this.dash>0?this.facing*570:approach(this.vx,axis*(this.dark>0?300:260),(this.grounded?2600:1700)*dt);
  if(this.swordPending>0){this.swordPending=Math.max(0,this.swordPending-dt);if(this.swordPending===0)this.resolveSword();}
  if(input.sword)this.sword();if(input.play)this.play();if(input.replace!==undefined)this.deck.replace(input.replace);
  this.coyote=this.grounded?.12:Math.max(0,this.coyote-dt);this.tryJump();
  const oldX=this.x,oldY=this.y,wasGround=this.grounded;this.x=clamp(this.x+this.vx*dt,12,WIDTH-12);
  if(!this.dash)this.vy+=1300*dt;this.y+=this.vy*dt;this.grounded=false;this.surface=-1;
  if(this.vy>=0){let landing=null;for(const p of this.platforms){if(this.drop>0&&!p.ground)continue;if(this.x+9>p.x&&this.x-9<p.x+p.w&&oldY<=p.y+.5&&this.y>=p.y&&(!landing||p.y<landing.y))landing=p}if(landing){this.y=landing.y;this.vy=0;this.grounded=true;this.surface=landing.id;if(!wasGround){this.land=.12;this.emit('land')}this.tryJump()}}
  if(!this.grounded||Math.abs(this.vx)>10||this.attack>0||this.dash>0)this.morphPose=false;
  if(this.y>530){this.invincible=0;this.hurt();this.fallCount++;this.x=this.checkpoint.x;this.y=this.checkpoint.y;this.vx=0;this.vy=0;this.dash=0;this.buffer=0;this.grounded=true;this.coyote=.12}
  if(!this.arena&&this.grounded&&this.y===420){
   this.clearing.checkpoints.forEach((x,i)=>{if(this.x>x&&this.checkpointId<i+1){this.checkpointId=i+1;this.checkpoint={x,y:420};this.emit('checkpoint');this.banner='LANTERN LIT · CHECKPOINT';this.bannerTime=1.6;}});
  }
  this.embers=this.embers.filter(e=>{if(Math.hypot(e.x-this.x,e.y-(this.y-18))<24){this.collected++;this.emit('pickup_essence');this.banner=this.collected===3?'THREE FLAMES · THE WAY IS OPEN':`FLAME ${this.collected} / 3`;this.bannerTime=1.8;return false}return true});
  if(!this.arena&&this.collected===3&&Math.hypot(this.x-this.clearing.exit.x,this.y-this.clearing.exit.y)<28){this.mode='won';return}
  updateEnemies(this,dt);updateEnemyShots(this,dt);
  for(const b of this.bolts){let old=b.x;b.x+=b.dir*680*dt;b.life-=dt;for(const e of this.enemies){if(e.x<Math.min(old,b.x)-22||e.x>Math.max(old,b.x)+22||Math.abs(e.y-23-b.y)>(b.tier>=5?65:30)||b.hit.has(e.id))continue;b.hit.add(e.id);if(b.tier===2)this.blast(e.x,e.y-22,100,b.damage,false,b.impact);else{this.damage(e,b.damage,b.dir*(30+b.tier*5));this.pokerImpact(b.impact,e.hp<=0)}if(b.tier<3){b.life=0;break}}}
  this.bolts=this.bolts.filter(b=>b.life>0);this.removeDead();
  for(const r of this.impacts)r.life-=dt;this.impacts=this.impacts.filter(r=>r.life>0);
  for(const r of this.corpses)r.life-=dt;this.corpses=this.corpses.filter(r=>r.life>0);
  for(const r of this.rings)r.life-=dt;this.rings=this.rings.filter(r=>r.life>0);
  for(const n of this.texts){n.life-=dt;n.y-=35*dt}this.texts=this.texts.filter(n=>n.life>0);
  for(const p of this.particles){p.life-=dt;p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=250*dt}this.particles=this.particles.filter(p=>p.life>0);
  const pickupStart=Math.abs(this.x-oldX)>100?this.x:oldX;
  for(const drop of this.cardDrops){
   drop.age+=dt;
   if(drop.blocked){if(Math.abs(drop.x-this.x)>32||Math.abs(drop.y-this.y)>40)drop.blocked=false;continue;}
   if(drop.age<.4||Math.abs(drop.y-this.y)>26)continue;
   if(drop.x>=Math.min(pickupStart,this.x)-18&&drop.x<=Math.max(pickupStart,this.x)+18&&this.openDraft(drop))break;
  }
 }
}
