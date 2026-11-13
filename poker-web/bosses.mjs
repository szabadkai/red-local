// Boss tells commit to a position/direction before the strike. No random attacks.
const clamp=(n,a,b)=>Math.max(a,Math.min(b,n));
export const BOSS_STATS={
 hart:{hp:80,speed:92,reach:290,tell:.95,recovery:1.65},
 tollkeeper:{hp:104,speed:65,reach:180,tell:1.05,recovery:1.8},
 rowan:{hp:90,speed:100,reach:140,tell:.8,recovery:1.65},
 widow:{hp:120,speed:80,reach:300,tell:1.1,recovery:1.65},
 wolf:{hp:140,speed:115,reach:250,tell:.85,recovery:1.5}
};
export function makeBoss(kind,id,garden=false){
 const def=BOSS_STATS[kind],hp=garden?90:def.hp;
 return {id,kind,boss:true,x:690,y:420,left:58,right:902,hp,max:hp,face:-1,state:'approach',
  timer:.6,flash:0,walk:0,phase:1,cycle:0,pattern:'',garden,wind:0,rest:0,connected:false};
}
function warn(world,kind,x,y,w,h,delay=.75,extra={}){
 world.hazards.push({kind,x,y,w,h,delay,life:.24,age:0,...extra});
}
export function damageBoss(world,boss,amount){
 if(boss.kind==='rowan'&&boss.state!=='recover'){
  if(!boss.blockFlash){world.texts.push({x:boss.x-22,y:boss.y-70,text:'GUARD',life:.5});boss.blockFlash=.4;}
  return false;
 }
 boss.hp-=amount;boss.flash=.16;
 world.texts.push({x:boss.x,y:boss.y-76,text:String(amount),life:.7});
 world.impacts.push({x:boss.x,y:boss.y-28,amount,life:.25,knockout:boss.hp<=0});
 return true;
}
export function updateBoss(world,dt){
 const b=world.boss;if(!b||b.hp<=0)return;
 const def=BOSS_STATS[b.kind];b.flash=Math.max(0,b.flash-dt);b.blockFlash=Math.max(0,(b.blockFlash||0)-dt);
 b.phase=b.hp<=b.max/2?2:1;b.walk+=dt;
 if(b.state==='recover'){
  b.timer-=dt;b.y=420;if(b.timer<=0){b.state='approach';b.timer=0;}return;
 }
 if(b.state==='approach'){
  b.face=Math.sign(world.x-b.x)||b.face;
  const dx=Math.abs(world.x-b.x);
  if(dx>def.reach){b.x=clamp(b.x+b.face*def.speed*dt,b.left,b.right);return;}
  b.timer-=dt;if(b.timer>0)return;
  b.state='windup';b.timer=def.tell*(b.garden?.85:1);b.wind=b.timer;b.target=clamp(world.x,75,885);b.targetY=world.y-22;b.strikeDir=b.face;
  const alternate=b.cycle++%2===1;
  b.pattern=b.kind==='hart'?(b.phase===2&&alternate?'roots':'charge'):
   b.kind==='tollkeeper'?(alternate?'slam':'chain'):
   b.kind==='rowan'?(b.phase===2&&alternate?'axe':'cut'):
   b.kind==='widow'?(b.phase===2&&alternate?'rings':'silk'):
   alternate?'leap':'bite';
  if(b.pattern==='roots')for(const x of [b.target-90,b.target+90])warn(world,'roots',clamp(x,65,895),420,42,58,b.timer);
  if(b.pattern==='slam')warn(world,'slam',b.x,420,200,34,b.timer);
  if(b.pattern==='silk')for(const x of [b.target,b.target+(b.target<480?150:-150)])warn(world,'silk',x,420,48,180,b.timer);
  if(b.pattern==='leap')warn(world,'landing',b.target,420,100,38,b.timer+.6);
  return;
 }
 if(b.state==='windup'){
  b.timer-=dt;b.wind=Math.max(0,b.timer);if(b.timer>0)return;
  b.state='strike';b.connected=false;b.startX=b.x;b.elapsed=0;
  b.duration={charge:.65,roots:.25,chain:.4,slam:.3,axe:1.2,cut:.3,silk:.3,rings:.3,bite:.36,leap:.6}[b.pattern];
  if(b.pattern==='rings')for(const dir of [-1,1])warn(world,'ring',b.x+dir*45,420,30,20,0,{vx:dir*240,life:3});
  if(b.pattern==='axe')warn(world,'axe',b.x,b.targetY,30,30,0,{vx:b.strikeDir*340,life:1.2,origin:b.x,returning:true});
 }
 if(b.state==='strike'){
  b.elapsed+=dt;
  if(b.pattern==='charge'||b.pattern==='bite'){
   const old=b.x;b.x=clamp(b.x+b.strikeDir*(b.pattern==='charge'?440:460)*dt,b.left,b.right);
   if(world.x>Math.min(old,b.x)-40&&world.x<Math.max(old,b.x)+40&&Math.abs(world.y-b.y)<32)world.hurt();
  }
  if(b.pattern==='chain'&&Math.abs(world.x-b.x)<220&&world.y>395)world.hurt();
  if(b.pattern==='cut'&&(world.x-b.x)*b.strikeDir>-15&&(world.x-b.x)*b.strikeDir<115&&Math.abs(world.y-b.y)<38)world.hurt();
  if(b.pattern==='leap'){
   const p=Math.min(1,b.elapsed/.6);b.x=b.startX+(b.target-b.startX)*p;b.y=420-Math.sin(p*Math.PI)*130;
  }
  if(b.elapsed>=b.duration){b.state='recover';b.timer=def.recovery*(b.garden?.85:1);b.y=420;b.wind=0;}
 }
}
export function updateHazards(world,dt){
 for(const h of world.hazards){
  h.age+=dt;if(h.delay>0){h.delay-=dt;continue;}
  const old=h.x;h.life-=dt;
  if(h.returning&&h.life<.6&&!h.turned){h.vx=-h.vx;h.turned=true;}
  h.x+=(h.vx||0)*dt;
  const top=h.kind==='axe'?h.y-h.h/2:h.y-h.h;
  if(world.x+10>Math.min(old,h.x)-h.w/2&&world.x-10<Math.max(old,h.x)+h.w/2&&world.y>top&&world.y-32<h.y+(h.kind==='axe'?h.h/2:0))world.hurt();
 }
 world.hazards=world.hazards.filter(h=>h.delay>0||h.life>0);
}
