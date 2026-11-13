import {World} from './model.mjs';
import {CLEARINGS,loadJourney} from './journey.mjs';
import {STAGES,SCENES,arenaPlatforms} from './story-data.mjs';
import {makeBoss,damageBoss,updateBoss,updateHazards} from './bosses.mjs';

export const STORY_SAVE_KEY='red.poker.story.v3';
const PHASES=['trail','boss','inside','garden','cleared','home','complete'];
const allScenes=new Set(Object.keys(SCENES));
const clamp=(n,a,b)=>Math.max(a,Math.min(b,n));
export class StoryWorld extends World{
 reset(stageIndex=0,progress=null){
  super.reset(stageIndex);
  this.storyPhase='trail';this.storyLocation='trail';this.worldWidth=2400;this.bossPractice=false;
  this.seen=new Set(progress?.seen||[]);this.dialogue=null;this.boss=null;this.hazards=[];
  this.storyRevision=(this.storyRevision||0)+1;this.sceneClock=0;this.rescueClock=0;
  this.lastEncounterX=0;this.pendingVictory=false;this.knots=[];
  const phase=progress?.phase||'trail';
  if(phase==='boss'||phase==='garden')this.setupArena(phase);
  else if(phase==='inside')this.setupInside();
  else if(phase==='cleared'){this.setupArena(stageIndex===4?'garden':'boss');this.enemies=[];this.boss=null;this.storyPhase='cleared';this.mode='won';}
  else if(phase==='home'||phase==='complete'){this.setupHome();if(phase==='complete'){this.storyPhase='complete';this.mode='won';}}
  if(progress?.dialogue)this.startScene(progress.dialogue.id,progress.dialogue.index);
  else if(phase==='trail'&&stageIndex===0&&!this.seen.has('prologue'))this.startScene('prologue');
 }
 get stageStory(){return STAGES[this.stageIndex];}
 get objective(){
  if(this.practice)return this.arena?'Practice arena':`Find the three embers · ${this.collected}/3`;
  if(this.dialogue)return SCENES[this.dialogue.id].title;
  if(this.storyPhase==='inside')return `Free Grandmother · ${3-this.knots.filter(k=>k.hp>0).length}/3 knots`;
  if(this.storyPhase==='home')return 'Walk home with Grandmother';
  if(this.boss)return this.boss.kind==='rowan'?'Disarm the Huntsman':this.boss.garden?'Open the road home':this.stageStory.title;
  return this.stageStory.objective;
 }
 startScene(id,index=0){
  this.dialogue={id,index:clamp(index,0,SCENES[id].lines.length-1)};
  this.mode='cutscene';this.vx=0;this.vy=0;this.swordPending=0;this.attack=0;this.cast=0;
  this.buffer=0;this.dash=0;this.sceneClock=0;this.storyRevision++;
 }
 advanceDialogue(skip=false){
  if(this.mode!=='cutscene'||!this.dialogue)return false;
  const {id,index}=this.dialogue;
  if(!skip&&index<SCENES[id].lines.length-1){this.dialogue.index++;this.storyRevision++;return true;}
  this.seen.add(id);this.dialogue=null;this.mode='playing';this.storyRevision++;
  this.invincible=Math.max(this.invincible,1);this.vx=0;this.vy=0;this.buffer=0;this.swordPending=0;
  if(id===this.stageStory.outro&&id!=='breakfast'){this.storyPhase='cleared';this.mode='won';}
  if(id==='swallowed')this.startScene('inside');
  if(id==='breakfast'){this.setupHome();this.startScene('epilogue');}
  return true;
 }
 setupRoom(location){
  this.arena=true;this.storyLocation=location;this.worldWidth=960;
  this.platforms=arenaPlatforms(this.stageIndex,location);this.x=210;this.y=420;this.surface=0;
  this.vx=0;this.vy=0;this.grounded=true;this.coyote=.12;this.buffer=0;
  this.checkpoint={x:210,y:420};this.health=5;this.invincible=1;
  this.deck.reset();this.bolts=[];this.enemyShots=[];this.cardDrops=[];this.activeDraft=null;
  this.enemies=[];this.embers=[];this.hazards=[];this.impacts=[];this.corpses=[];this.rings=[];
  this.dark=0;this.transform=0;this.dash=0;this.attack=0;this.swordPending=0;this.cast=0;
  this.hitStop=0;this.shakeTime=0;this.banner='';this.bannerTime=0;this.boss=null;
  this.mode='playing';this.storyRevision++;
 }
 setupArena(phase='boss'){
  this.setupRoom(phase==='garden'?'garden':'arena');this.storyPhase=phase;
  this.boss=makeBoss(this.stageStory.boss,this.nextId++,phase==='garden');this.enemies=[this.boss];
  this.collected=3;
 }
 setupInside(){
  this.setupRoom('inside');this.storyPhase='inside';this.rescueClock=0;
  this.knots=[[240,360],[430,300],[620,240]].map(([x,y])=>({id:this.nextId++,kind:'knot',storyTarget:true,x,y,left:x,right:x,hp:8,max:8,face:1,state:'idle',flash:0,walk:0}));
  this.enemies=[...this.knots];this.collected=3;
 }
 setupHome(){
  this.setupRoom('home');this.storyPhase='home';this.x=180;this.collected=3;
 }
 retry(){
  const phase=this.practice?'trail':this.storyPhase;
  const seen=[...this.seen];this.reset(this.stageIndex,{phase:phase==='cleared'?'boss':phase,seen});
  if(this.boss){this.banner=this.stageStory.hint;this.bannerTime=4;}
 }
 advance(){
  if(this.mode!=='won'||this.practice||this.stageIndex>=STAGES.length-1)return false;
  const seen=[...this.seen];this.reset(this.stageIndex+1,{phase:'trail',seen});return true;
 }
 practiceDeal(kind){
  if(kind>=10){
   const stage=clamp(kind-10,0,4);this.reset(stage,{phase:'boss',seen:['prologue']});
   this.practice=true;this.bossPractice=true;this.banner=this.stageStory.hint;this.bannerTime=5;return;
  }
  super.practiceDeal(kind);this.dialogue=null;this.mode='playing';this.bossPractice=false;this.storyLocation='trail';
 }
 damage(e,amount,push){
  if(e.boss)return damageBoss(this,e,amount);
  if(e.storyTarget){e.hp-=amount;e.flash=.16;this.impacts.push({x:e.x,y:e.y-20,amount,life:.25});return true;}
  super.damage(e,amount,push);return true;
 }
 removeDead(){
  const boss=this.enemies.find(e=>e.boss&&e.hp<=0);
  // Living story characters are freed/disarmed, not sent to the normal corpse renderer.
  const freed=this.enemies.filter(e=>e.storyTarget&&e.hp<=0);
  this.enemies=this.enemies.filter(e=>!(e.boss&&e.hp<=0)&&!(e.storyTarget&&e.hp<=0));
  if(freed.length){this.emit('checkpoint');this.storyRevision++;}
  super.removeDead();if(boss){this.pendingVictory=true;this.kills++;}
 }
 step(dt,input={}){
  if(this.mode!=='playing')return;
  const stopped=this.hitStop>0;
  // The mill wheel carries its two ledges in opposite directions after the lock cracks.
  if(!stopped&&this.boss?.kind==='tollkeeper'&&this.boss.hp<=this.boss.max/2){
   for(const p of this.platforms.slice(1)){
    const nextY=360+Math.sin((this.time+dt)*1.2+(p.id===1?0:Math.PI))*28;
    if(this.grounded&&this.surface===p.id)this.y+=nextY-p.y;
    p.y=nextY;
   }
  }
  super.step(dt,input);
  if(this.practice&&!this.bossPractice)return;
  if(this.mode==='dead'||stopped)return;
  if(this.storyLocation!=='trail')this.x=clamp(this.x,24,936);
  if(this.pendingVictory){
   this.pendingVictory=false;this.boss=null;this.hazards=[];this.bolts=[];this.enemyShots=[];this.cardDrops=[];this.activeDraft=null;
   if(this.practice){this.mode='won';return;}
   if(this.stageIndex===4&&this.storyPhase==='boss'){this.setupInside();this.startScene('swallowed');}
   else{this.storyPhase='cleared';this.startScene(this.stageStory.outro);}
   return;
  }
  if(this.mode!=='playing'&&this.mode!=='won')return;
  if(this.storyPhase==='trail'){
   // Reaching the lantern opens an authored encounter room rather than completing the story stage.
   if(this.mode==='won'){this.setupArena();this.startScene(this.stageStory.intro);return;}
   if(this.x>=160&&this.grounded&&!this.seen.has(this.stageStory.encounter)){
    this.startScene(this.stageStory.encounter);return;
   }
  }
  if(this.boss){updateBoss(this,dt);updateHazards(this,dt);}
  if(this.storyPhase==='inside'){
   this.rescueClock+=dt;for(const k of this.knots)k.flash=Math.max(0,k.flash-dt);
   if(this.rescueClock>=3.2){this.rescueClock=0;this.emit('checkpoint');
    this.hazards.push({kind:'shadow',x:this.x,y:this.y,w:64,h:34,delay:1.1,life:.25,age:0});
   }
   updateHazards(this,dt);
   if(this.knots.every(k=>k.hp<=0)&&this.x>840){this.setupArena('garden');this.startScene('garden');return;}
  }
  if(this.storyPhase==='home'&&this.x>=820){this.storyPhase='complete';this.mode='won';this.storyRevision++;}
 }
 snapshot(){return {version:3,clearing:this.clearing.id,phase:this.storyPhase,seen:[...this.seen],dialogue:this.dialogue?{...this.dialogue}:null};}
}
export function loadStory(storage){
 try{
  const raw=storage.getItem(STORY_SAVE_KEY);
  if(!raw){const old=loadJourney(storage);return old?{stage:old.stage,phase:'trail',seen:[],dialogue:null,complete:false}:null;}
  const data=JSON.parse(raw),stage=CLEARINGS.findIndex(c=>c.id===data?.clearing);
  if(data?.version!==3||stage<0||!PHASES.includes(data.phase))return null;
  if(['inside','garden','home','complete'].includes(data.phase)&&stage!==4)return null;
  if(!Array.isArray(data.seen)||data.seen.some(id=>!allScenes.has(id)))return null;
  const d=data.dialogue;
  if(d&&(!allScenes.has(d.id)||!Number.isInteger(d.index)||d.index<0||d.index>=SCENES[d.id].lines.length))return null;
  const allowed={trail:[stage===0?'prologue':null,STAGES[stage].encounter],boss:[STAGES[stage].intro],inside:['swallowed','inside'],garden:['garden'],cleared:[STAGES[stage].outro],home:['epilogue'],complete:[]};
  if(d&&!allowed[data.phase].includes(d.id))return null;
  return {stage,phase:data.phase,seen:data.seen,dialogue:d||null,complete:data.phase==='complete'};
 }catch{return null;}
}
export function saveStory(storage,world){
 if(world.practice)return false;
 try{storage.setItem(STORY_SAVE_KEY,JSON.stringify(world.snapshot()));return true;}catch{return false;}
}
