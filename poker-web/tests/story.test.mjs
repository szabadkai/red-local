import {test} from 'node:test';
import assert from 'node:assert/strict';
import {StoryWorld,STORY_SAVE_KEY,loadStory,saveStory,BOSS_DEATH} from '../story.mjs';
import {SCENES,STAGES,arenaPlatforms} from '../story-data.mjs';
import {bossInput} from './support/story-player.mjs';
import {updateBoss,updateHazards} from '../bosses.mjs';
const tick=(w,n,input={})=>{for(let i=0;i<n;i++)w.step(1/60,input);};
const skip=w=>{while(w.mode==='cutscene')w.advanceDialogue(true);};
const storage=()=>{const memory=new Map();return {memory,getItem:k=>memory.get(k)??null,setItem:(k,v)=>memory.set(k,v)};};
function arrive(w){w.enemies=[];w.collected=3;w.embers=[];w.x=w.clearing.exit.x;w.y=w.clearing.exit.y;w.grounded=true;w.vy=0;w.step(1/60);}
function defeat(w){w.boss.state='recover';w.damage(w.boss,w.boss.hp,0);w.removeDead();tick(w,Math.ceil(BOSS_DEATH*60)+30);}
function walk(w,target,jump=false){
 if(jump)w.jump();
 for(let i=0;i<300;i++){
  const d=target-w.x;w.step(1/60,{axis:Math.abs(d)<1?0:Math.max(-1,Math.min(1,d/22))});
  if(w.mode==='won')return;
  if(w.mode==='cutscene'){skip(w);continue;}
  if(Math.abs(d)<4&&Math.abs(w.vx)<10&&w.grounded)return;
 }
 assert.fail(`Could not reach ${target}: ${w.x}, ${w.y}`);
}

test('dialogue freezes physics, attacks, hazards and the deck; skipping has identical outcomes',()=>{
 const a=new StoryWorld(()=>.5),b=new StoryWorld(()=>.5);
 const before={time:a.time,x:a.x,hp:a.health,hand:[...a.deck.hand]};
 tick(a,240,{axis:1,sword:true,jump:true,play:true});
 assert.deepEqual({time:a.time,x:a.x,hp:a.health,hand:a.deck.hand},before);
 while(a.mode==='cutscene')a.advanceDialogue();b.advanceDialogue(true);
 assert.deepEqual(a.snapshot(),b.snapshot());assert.equal(a.mode,'playing');
 for(let stage=0;stage<5;stage++){
  a.reset(stage,{phase:'boss',seen:[]});b.reset(stage,{phase:'boss',seen:[]});
  a.startScene(STAGES[stage].intro);b.startScene(STAGES[stage].intro);
  while(a.mode==='cutscene')a.advanceDialogue();b.advanceDialogue(true);
  assert.deepEqual(a.snapshot(),b.snapshot());assert.equal(a.boss.hp,b.boss.hp);
 }
});

test('every route requires three embers, then enters its own boss instead of advancing',()=>{
 for(let stage=0;stage<5;stage++){
  const w=new StoryWorld();w.reset(stage,{phase:'trail',seen:[STAGES[stage].encounter,'prologue']});
  w.x=w.clearing.exit.x;w.y=w.clearing.exit.y;w.step(1/60);assert.equal(w.storyPhase,'trail');
  arrive(w);assert.equal(w.mode,'cutscene');assert.equal(w.dialogue.id,STAGES[stage].intro);
  assert.equal(w.boss.kind,STAGES[stage].boss);assert.equal(w.storyPhase,'boss');assert.equal(w.health,5);
  assert.equal(w.worldWidth,960);skip(w);assert.equal(w.mode,'playing');assert.equal(w.advance(),false);
 }
});

test('full story progression rescues Grandmother, fights the garden Wolf, then walks home',()=>{
 const w=new StoryWorld();skip(w);
 for(let stage=0;stage<5;stage++){
  w.x=170;w.y=420;w.grounded=true;w.step(1/60);assert.equal(w.dialogue.id,STAGES[stage].encounter);skip(w);
  arrive(w);skip(w);defeat(w);
  if(stage<4){assert.equal(w.dialogue.id,STAGES[stage].outro);skip(w);assert.equal(w.mode,'won');assert.equal(w.advance(),true);}
 }
 assert.equal(w.dialogue.id,'swallowed');assert.equal(w.storyPhase,'inside');skip(w);
 assert.equal(w.knots.length,3);w.x=900;w.step(1/60);assert.equal(w.storyPhase,'inside','cannot exit before rescuing Grandmother');
 for(const k of w.knots)w.damage(k,k.hp,0);w.removeDead();w.step(1/60);
 assert.equal(w.storyPhase,'garden');assert.equal(w.dialogue.id,'garden');skip(w);
 assert.equal(w.boss.garden,true);assert.equal(w.boss.hp,90);defeat(w);
 assert.equal(w.dialogue.id,'breakfast');skip(w);assert.equal(w.storyPhase,'home');assert.equal(w.mode,'playing');
 walk(w,830);assert.equal(w.mode,'won');assert.equal(w.storyPhase,'complete');assert.equal(w.advance(),false);
});

test('save and reload restore every dialogue and boss phase without skipping an encounter',()=>{
 const s=storage(),w=new StoryWorld();
 for(const [stage,phase,id] of [[0,'trail','prologue'],[0,'boss','hartIntro'],[1,'boss','tollIntro'],[2,'cleared','rowanOutro'],[4,'inside','swallowed'],[4,'inside','inside'],[4,'garden','garden'],[4,'cleared','breakfast'],[4,'home','epilogue']]){
  w.reset(stage,{phase,seen:[],dialogue:{id,index:1}});assert.equal(saveStory(s,w),true);
  const saved=loadStory(s);assert.ok(saved);const restored=new StoryWorld();restored.reset(saved.stage,saved);
  assert.deepEqual(restored.snapshot(),w.snapshot());assert.equal(restored.mode,'cutscene');skip(restored);
  assert.notEqual(restored.mode,'dead');
 }
 for(const phase of ['boss','inside','garden','home','complete']){
  w.reset(4,{phase,seen:['prologue']});saveStory(s,w);const saved=loadStory(s);const restored=new StoryWorld();restored.reset(saved.stage,saved);
  assert.equal(restored.storyPhase,phase);assert.equal(restored.health,5);
 }
});

test('retry keeps the encounter phase, replenishes resources, clears hazards and never overwrites practice saves',()=>{
 const s=storage(),w=new StoryWorld();
 for(const phase of ['boss','inside','garden']){
  w.reset(4,{phase,seen:['prologue']});w.health=1;w.deck.play();w.hazards.push({life:99});w.mode='dead';w.retry();
  assert.equal(w.storyPhase,phase);assert.equal(w.health,5);assert.equal(w.deck.hand.length,5);assert.equal(w.hazards.length,0);assert.equal(w.mode,'playing');
 }
 saveStory(s,w);const before=s.getItem(STORY_SAVE_KEY);
 for(let kind=0;kind<=14;kind++){
  w.practiceDeal(kind);assert.equal(w.practice,true);assert.equal(w.mode,'playing');assert.equal(w.dialogue,null);assert.equal(saveStory(s,w),false);
 }
 assert.equal(s.getItem(STORY_SAVE_KEY),before);
});

test('save validation handles malformed data, wrong-stage cutscenes, old progress and blocked storage',()=>{
 const s=storage();
 for(const value of ['garbage','null','{}',JSON.stringify({version:3,clearing:'lantern-wood',phase:'garden',seen:[]}),JSON.stringify({version:3,clearing:'lantern-wood',phase:'boss',seen:[],dialogue:{id:'epilogue',index:0}})]){
  s.setItem(STORY_SAVE_KEY,value);assert.equal(loadStory(s),null);
 }
 const legacy={getItem:key=>key==='red.poker.journey.v2'?JSON.stringify({version:2,clearing:'moss-cavern'}):null};
 assert.equal(loadStory(legacy).stage,2);
 const blocked={getItem(){throw Error('blocked')},setItem(){throw Error('blocked')}};
 assert.equal(loadStory(blocked),null);assert.equal(saveStory(blocked,new StoryWorld()),false);
});

test('bosses commit tells, expose recovery, and use a second-phase pattern',()=>{
 for(let stage=0;stage<5;stage++){
  const w=new StoryWorld();w.reset(stage,{phase:'boss',seen:[]});const b=w.boss;
  w.x=b.x-70;b.timer=0;updateBoss(w,1/60);assert.equal(b.state,'windup');
  const direction=b.strikeDir;w.x=b.x+70;updateBoss(w,.1);assert.equal(b.strikeDir,direction,'tell must not track Red');
  for(let i=0;i<200&&b.state!=='recover';i++)updateBoss(w,1/60);
  assert.equal(b.state,'recover');const hp=b.hp;w.damage(b,2,0);assert.equal(b.hp,hp-2);
  b.hp=b.max/2;b.timer=0;w.x=b.x+(b.x<480?60:-60);updateBoss(w,1/60);updateBoss(w,1/60);
  assert.equal(b.phase,2);assert.ok(['roots','slam','axe','rings','leap'].includes(b.pattern),b.pattern);
 }
});

test('Huntsman guard blocks damage and draw credit; recovery allows ordinary sword damage',()=>{
 const w=new StoryWorld();w.reset(2,{phase:'boss',seen:[]});w.x=w.boss.x-45;w.facing=1;
 w.boss.state='windup';const hp=w.boss.hp;w.attackFacing=1;w.attackForm='light';w.resolveSword();
 assert.equal(w.boss.hp,hp);assert.equal(w.deck.hits,0);
 w.boss.state='recover';w.resolveSword();assert.equal(w.boss.hp,hp-2);assert.equal(w.deck.hits,1);
});

test('telegraphed hazards give warning, can be jumped or dashed, and freeze during card choice',()=>{
 const w=new StoryWorld();w.reset(1,{phase:'boss',seen:[]});w.invincible=0;
 w.hazards=[{kind:'slam',x:w.x,y:420,w:120,h:30,delay:.5,life:.3,age:0}];
 updateHazards(w,.25);assert.equal(w.health,5);updateHazards(w,.26);assert.equal(w.health,5);
 w.y=360;updateHazards(w,.05);assert.equal(w.health,5);
 w.y=420;w.startDash();updateHazards(w,.05);assert.equal(w.health,5);
 w.invincible=0;updateHazards(w,.05);assert.equal(w.health,4);
 w.mode='drafting';const before=JSON.stringify(w.hazards);tick(w,60);assert.equal(JSON.stringify(w.hazards),before);
});

test('the swallowed room can be climbed and its knots cut with ordinary jumps and sword swings',()=>{
 const w=new StoryWorld();w.reset(4,{phase:'inside',seen:[]});
 // This route verifies physical reach and interaction, not boss balance.
 for(const [x,y,k] of [[230,360,0],[420,300,1],[610,240,2]]){
  if(k)walk(w,x-110);
  walk(w,x,true);assert.equal(w.y,y);w.facing=1;
  for(let i=0;i<4;i++){w.sword();tick(w,20);if(w.mode==='drafting')w.dismissDraft();}
  assert.ok(w.knots[k].hp<=0);
 }
 walk(w,690);walk(w,790,true);walk(w,870);assert.equal(w.storyPhase,'garden');assert.equal(w.health,5);
});

test('all boss side ledges are reachable with the existing jump envelope',()=>{
 for(let stage=0;stage<5;stage++){
  const p=arenaPlatforms(stage);assert.equal(p[0].w,960);
  for(const ledge of p.slice(1))assert.ok(420-ledge.y<=65);
 }
});

for(const [stage,phase] of [[0,'boss'],[1,'boss'],[2,'boss'],[3,'boss'],[4,'boss'],[4,'garden']])test(`${STAGES[stage].title} ${phase}: defeatable with sword and ordinary movement, without rare hands`,()=>{
 const w=new StoryWorld(()=>.4);w.reset(stage,{phase,seen:[]});let ticks=0;
 for(;ticks<60*180&&w.boss&&w.mode!=='dead';ticks++){
  if(w.mode==='drafting'){w.chooseDraft(0);continue;}
  w.step(1/60,bossInput(w));
 }
 assert.notEqual(w.mode,'dead');assert.equal(w.boss,null);assert.ok(ticks<60*180);
});

test('the cracked mill lock starts moving platforms and carries a grounded rider',()=>{
 const w=new StoryWorld();w.reset(1,{phase:'boss',seen:[]});w.boss.hp=w.boss.max/2;
 const p=w.platforms[1];w.x=p.x+50;w.y=p.y;w.surface=p.id;w.grounded=true;
 tick(w,20);assert.notEqual(p.y,360);assert.equal(w.y,p.y);assert.equal(w.surface,p.id);
 const before=p.y;w.mode='paused';tick(w,20);assert.equal(p.y,before);
});

test('a beaten boss stays down for its death row before the outro',()=>{
 const w=new StoryWorld(()=>.5);w.reset(0,{phase:'boss',seen:['prologue']});skip(w);
 assert.ok(w.boss);w.boss.state='recover';w.damage(w.boss,w.boss.hp,0);w.removeDead();
 assert.equal(w.boss,null);assert.equal(w.hazards.length,0);assert.equal(w.bossCorpse?.kind,'hart');
 tick(w,Math.floor((BOSS_DEATH-.5)*60));
 assert.equal(w.mode,'playing');assert.ok(w.bossCorpse.time>1.4);
 tick(w,90);
 assert.equal(w.bossCorpse,null);assert.notEqual(w.mode,'playing');
});
