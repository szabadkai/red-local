import {drawBridgeBackdrop,drawBridgeArchitecture,drawBridgeAtmosphere,drawBriarDock} from './bridge.mjs';
import {CLEARINGS,loadJourney,saveJourney} from './journey.mjs';
import {prepareScenery,drawBackdrop,drawLandmarks,drawTrailGate,drawForeground} from './scenery.mjs';
import {PLAYER_CLIPS,playerClip,playerFrame} from './animation.mjs';
import {drawTerrain,drawHome} from './environment.mjs';
import {snap,characterSize,playerOffset,castShape,shakeOffset} from './art.mjs';
import {World,evaluate,EFFECTS,WIDTH,cardName,CORPSE_LIFE} from './model.mjs';
import {CAST,CELL,castFrame,castTop,deathFrame,idleFrame} from './cast.mjs';
const $=id=>document.getElementById(id),canvas=$('game'),screen=canvas.getContext('2d'),raster=document.createElement('canvas');
raster.width=960;raster.height=540;const ctx=raster.getContext('2d');
const world=new World(),keys=new Set(),edges=new Set();let releaseJump=false,started=false,loaded=false,muted=true;
let reduced=matchMedia('(prefers-reduced-motion: reduce)').matches,cam=0,accumulator=0,last=0,visual=0,hover=-1,toast='';
let previousMode='ready',lastHand='',formClock=0,lastAnim='',cameraSnap=true,lastDraft=null;
const images=new Map(),audio=new Map(),cards=new Map();
const storage={getItem:key=>localStorage.getItem(key),setItem:(key,value)=>localStorage.setItem(key,value)};
let savedJourney=loadJourney(storage),persistedCompletion=false;
const defs=PLAYER_CLIPS;
const tasks=[];
function loadImage(key,url){tasks.push(new Promise((resolve,reject)=>{const image=new Image();image.onload=()=>{images.set(key,image);resolve()};image.onerror=()=>reject(new Error('Could not load '+url));image.src=url}))}
for(const form of ['light','dark'])for(const [state,[count,prefix]] of Object.entries(defs))for(let i=0;i<count;i++)loadImage(`${form}/${state}/${i}`,`./assets/${form}/${state}/${prefix}${form==='light'&&state==='attack3'?String(i).padStart(2,'0'):i}.png`);
for(let i=1;i<=7;i++)loadImage('forest'+i,`./assets/forest/${i}.png`);
for(const [form,fx] of [['light','FX_light'],['light','FX_lighttodark'],['dark','FX_dark'],['dark','FX_darktolight']])for(let i=0;i<36;i++)loadImage(`${fx}/${i}`,`./assets/${form}/${fx}/${fx}${i}.png`);
loadImage('cave','./assets/environment/cave.png');
loadImage('terrain','./assets/environment/terrain.png');loadImage('gothic','./assets/environment/gothic.png');
for(const name of ['forest','stone','thorn-house','oaks','moss-cavern-v2','ruined-chapel-v2','interior-props-v2','masonry-v2'])loadImage('concept-'+name,`./assets/concept/${name==='oaks'?'parallax-oaks':name}.png`);
for(const name of ['bridge-atlas-v1','bridge-distance-v1','bridge-bough-v1'])loadImage('concept-'+name,`./assets/concept/${name}.png`);
loadImage('cards','./assets/cards.png');loadImage('dungeon','./assets/dungeon.png');for(const name of Object.keys(CAST))loadImage('cast/'+name,`./assets/cast/${name}_sheet.png`);
for(const name of ['attack1','attack3','transform_dark','meter_full','jump','land','player_hurt','pickup_essence','checkpoint']){let a=new Audio(`./assets/${name}.ogg`);a.volume=.16;audio.set(name,a)}
const total=tasks.length;let done=0;tasks.forEach(p=>p.then(()=>{$('loading').textContent=`Opening the forest · ${Math.round(++done/total*100)}%`},()=>{}));
Promise.all(tasks).then(()=>{prepareScenery(images);loaded=true;$('begin').disabled=false;$('begin').textContent='Begin journey';$('continue').hidden=!savedJourney;$('continue').textContent=savedJourney?.complete?'Replay final clearing':'Continue journey';$('save-status').textContent=savedJourney?`Saved: ${CLEARINGS[savedJourney.stage].name} · this browser`:'';$('loading').textContent='Keyboard controls · headphones welcome';updateUI(true)}).catch(err=>{$('begin').textContent='Reload to retry';$('loading').textContent=err.message;console.error(err)});
function sound(name){if(muted)return;let a=audio.get(name);if(a){a.currentTime=0;a.play().catch(()=>{})}}
const musicTracks=new Map(['forest_theme','boss_theme'].map(name=>{const a=new Audio(`./assets/${name}.ogg`);a.loop=true;a.volume=.07;return [name,a]}));let musicKey='';
function syncMusic(){
 const next=muted||!started||world.mode==='paused'||world.mode==='dead'||document.hidden?'':['cave','chapel','house'].includes(world.clearing.theme)?'boss_theme':'forest_theme';
 if(next===musicKey)return;for(const a of musicTracks.values())a.pause();musicKey=next;if(next)musicTracks.get(next).play().catch(()=>{});
}
function focusGame(){if(world.mode!=='drafting')$('stage').focus({preventScroll:true})}
function clearInput(){keys.clear();edges.clear();releaseJump=false;accumulator=0}
function enterWorld(){lastAnim='';lastHand='';formClock=0;cam=0;cameraSnap=true;cardPositions.clear();departing.length=0;clearInput();started=true;persistedCompletion=false;$('overlay').hidden=true;updateUI(true);focusGame()}
function persistJourney(){if(world.practice){$('save-status').textContent='Practice leaves your saved journey untouched';return;}const ok=saveJourney(storage,world);if(ok)savedJourney=loadJourney(storage);$('save-status').textContent=ok?'Progress saved at this clearing · this browser':'Saving unavailable · keep this tab open';}
function reset(fresh=false){if(fresh)world.reset();else if(world.practice){world.reset(savedJourney?.stage||0)}else world.retry();enterWorld();persistJourney()}
function nextClearing(){if(world.advance()){enterWorld();persistJourney();sound('checkpoint')}}
function pause(){if(!started)return;clearInput();if(world.mode==='playing')world.mode='paused';else if(world.mode==='paused')world.mode='playing';updateUI(true)}
function press(code){if(keys.has(code))return;keys.add(code);edges.add(code)}
function release(code){keys.delete(code);if(code==='Space')releaseJump=true}
const controls=['KeyA','KeyD','ArrowLeft','ArrowRight','Space','ShiftLeft','ShiftRight','KeyJ','KeyK','KeyS','ArrowDown','KeyP','Escape','KeyR','Digit1','Digit2','Digit3','Digit4','Digit5'];
window.addEventListener('keydown',e=>{
 if(world.mode==='drafting'){
  if(e.repeat){e.preventDefault();return;}
  if(e.code==='Digit1'||e.code==='Digit2'){e.preventDefault();finishDraft(Number(e.code.slice(-1))-1)}
  else if(e.code==='Escape'||e.code==='KeyP'){e.preventDefault();finishDraft(null)}
  else if(e.code==='Tab'){e.preventDefault();const buttons=[$('draft-left'),$('draft-right'),$('draft-skip')],i=buttons.indexOf(document.activeElement);buttons[(i+(e.shiftKey?2:1)+3)%3].focus()}
  else if(controls.includes(e.code))e.preventDefault();
  return;
 }
 if(e.target.matches('select,input')||!controls.includes(e.code))return;e.preventDefault();if(e.repeat)return;
 if(e.code==='KeyP'||e.code==='Escape'){pause();return}if(e.code==='KeyR'){if(loaded)reset();return}if(!started||world.mode!=='playing')return;press(e.code)});
window.addEventListener('keyup',e=>{if(controls.includes(e.code)){e.preventDefault();release(e.code)}});
window.addEventListener('blur',()=>{clearInput();if(started&&world.mode==='playing'){world.mode='paused';updateUI(true)}});
document.addEventListener('visibilitychange',()=>{if(document.hidden){clearInput();if(started&&world.mode==='playing'){world.mode='paused';updateUI(true)}}});
$('begin').onclick=()=>{if(!loaded)return;if(world.mode==='paused'){world.mode='playing';clearInput();$('overlay').hidden=true;focusGame()}else if(world.mode==='won'&&world.practice)reset();else if(world.mode==='won'&&world.stageIndex<CLEARINGS.length-1)nextClearing();else reset(!started||world.mode==='won')};
$('continue').onclick=()=>{if(loaded&&savedJourney){world.reset(savedJourney.stage);enterWorld();persistJourney()}};
$('new-journey').onclick=()=>{if(loaded)reset(true)};
$('restart').onclick=()=>{if(loaded)reset()};$('pause').onclick=()=>{pause();focusGame()};
$('play').onclick=()=>{if(started&&world.mode==='playing'){world.play();updateUI(true);focusGame()}};
$('sound').onclick=()=>{muted=!muted;$('sound').textContent=muted?'Sound off':'Sound on';$('sound').setAttribute('aria-pressed',String(!muted));if(muted)for(const a of audio.values())a.pause();else sound('meter_full');focusGame()};
function motion(){document.body.classList.toggle('reduced',reduced);$('motion').textContent=reduced?'Motion off':'Motion on';$('motion').setAttribute('aria-pressed',String(!reduced))}motion();
$('motion').onclick=()=>{reduced=!reduced;motion();focusGame()};
$('deal').onclick=()=>{if(!loaded)return;world.practiceDeal(Number($('practice').value));enterWorld()};
$('stage').addEventListener('pointerdown',event=>{if(world.mode!=='drafting'&&!event.target.closest('button,select,summary,a'))focusGame()});
$('draft-left').onclick=()=>finishDraft(0);$('draft-right').onclick=()=>finishDraft(1);$('draft-skip').onclick=()=>finishDraft(null);
for(const button of document.querySelectorAll('[data-hold]')){button.onpointerdown=e=>{e.preventDefault();button.setPointerCapture(e.pointerId);if(started&&world.mode==='playing')press(button.dataset.hold)};button.onpointerup=button.onpointercancel=button.onlostpointercapture=()=>release(button.dataset.hold)}
function finishDraft(index){
 if(world.mode!=='drafting')return;
 if(index===null)world.dismissDraft();else if(!world.chooseDraft(index))return;
 clearInput();updateUI(true);focusGame();
}
function draftHint(card){
 const hand=world.deck.hand,candidates=hand.length<5?[[...hand,card]]:hand.map((_,slot)=>hand.map((id,i)=>i===slot?card:id));
 const best=candidates.map(evaluate).sort((a,b)=>b.tier-a.tier)[0],suit=Math.floor(card/13),suited=hand.filter(id=>Math.floor(id/13)===suit).length;
 if(suited>=2&&best.tier<=evaluate(hand).tier)return `${Math.min(5,suited+1)} ${['spades','diamonds','clubs','hearts'][suit]} available`;
 return (hand.length===5?'Best swap: ':'Hand becomes: ')+best.name;
}
function updateDraftUI(){
 const choosing=world.mode==='drafting';$('draft-overlay').hidden=!choosing;
 $('overlay').inert=choosing;document.body.classList.toggle('drafting',choosing);document.querySelector('.table').inert=choosing;document.querySelector('#stage>nav').inert=choosing;
 if(!choosing){lastDraft=null;return;}
 if(lastDraft===world.activeDraft)return;
 lastDraft=world.activeDraft;clearInput();
 const offer=world.deck.drafts.find(d=>d.id===world.activeDraft);
 $('draft-detail').textContent=world.deck.hand.length===5?'Your hand is full. Save one card, then use 1–5 to replace a slot.':'Choose one for your hand. The other card will vanish.';
 offer.cards.forEach((id,i)=>{
  const button=$(i?'draft-right':'draft-left'),c=button.querySelector('canvas').getContext('2d');let rank=id%13+2;if(rank===14)rank=1;
  c.clearRect(0,0,32,48);c.imageSmoothingEnabled=false;c.drawImage(images.get('cards'),32+(Math.floor((rank-1)/3)*4+Math.floor(id/13))*32,32+((rank-1)%3)*48,32,48,0,0,32,48);
  button.querySelector('strong').textContent=cardName(id);button.querySelector('small').textContent=draftHint(id);button.setAttribute('aria-label',`Take ${cardName(id)} (${i+1})`);
 });
 $('draft-left').focus({preventScroll:true});
}
function updateUI(force=false){
 updateDraftUI();syncMusic();document.body.classList.toggle('at-title',!started);
 $('chapter-label').textContent=world.arena?'PRACTICE ARENA':`${['I','II','III','IV','V'][world.stageIndex]} · ${world.clearing.name.toUpperCase()}`;
 const trailKey=world.arena?'arena':String(world.stageIndex);
 if($('trail-dots').dataset.stage!==trailKey){$('trail-dots').dataset.stage=trailKey;$('trail-dots').innerHTML=CLEARINGS.map((c,i)=>`<i class="${!world.practice&&i<=world.stageIndex?'lit':''}" title="${c.name}"></i>`).join('');$('trail-dots').setAttribute('aria-label',`Clearing ${world.stageIndex+1} of ${CLEARINGS.length}`);}
 $('health').innerHTML=Array.from({length:5},(_,i)=>`<i class="heart ${i<world.health?'full':''}"></i>`).join('');$('health').setAttribute('aria-label',`${world.health} of 5 health`);
 $('quest').textContent=world.arena?'Practice arena':`${world.collected} / 3 embers`;
 const r=evaluate(world.deck.hand);$('combo').textContent=r.name;$('effect').textContent=r.tier<0?'Land sword hits to refill':`${EFFECTS[r.tier]} · ${r.damage} damage`;
 $('play').disabled=!started||world.mode!=='playing'||!world.deck.hand.length;
 $('draw-label').textContent=world.deck.banked?'Saved: '+cardName(world.deck.reserve):`Sword hits ${world.deck.hits} / 3`;
 $('draw-help').textContent=world.deck.banked?'1–5: replace a slot with your saved card.':world.cardDrops.length?'Touch a card drop to reveal two choices.':'Three landed swings drop one card.';
 $('deck-count').textContent=`${world.deck.pile.length} in deck · ${world.deck.discard.length} spent${world.cardDrops.length?' · '+world.cardDrops.length+' dropped':''}`;
 [...$('pips').children].forEach((p,i)=>p.classList.toggle('lit',world.deck.banked||i<world.deck.hits));
 const sig=world.deck.hand.join(',');if(sig!==lastHand||force){lastHand=sig;
  for(const [id,el] of cards)if(!world.deck.hand.includes(id)){el.classList.add('out');setTimeout(()=>el.remove(),280);cards.delete(id)}
  $('hand').querySelectorAll('.empty-slot').forEach(e=>e.remove());
  for(let i=0;i<5;i++){const slot=document.createElement('div');slot.className='empty-slot';slot.style.left=`${i*72+15}px`;slot.style.setProperty('--slot',i);$('hand').append(slot)}
  world.deck.hand.forEach((id,i)=>{let el=cards.get(id);if(!el){el=document.createElement('button');el.className='card in';el.innerHTML='<span class="slot"></span><canvas width="32" height="48"></canvas>';const c=el.querySelector('canvas').getContext('2d');let rank=id%13+2;if(rank===14)rank=1;let sx=32+(Math.floor((rank-1)/3)*4+Math.floor(id/13))*32,sy=32+((rank-1)%3)*48;c.drawImage(images.get('cards'),sx,sy,32,48,0,0,32,48);el.onclick=()=>{if(!started||world.mode!=='playing')return;let index=world.deck.hand.indexOf(id);if(world.deck.replace(index)){sound('meter_full');updateUI(true)}else{world.banner='TOUCH A CARD DROP TO CHOOSE YOUR DRAW';world.bannerTime=1.8}focusGame()};el.onpointerenter=()=>hover=id;el.onpointerleave=()=>hover=-1;$('hand').append(el);cards.set(id,el)}
   const rank=id%13+2,label=rank===14?'Ace':rank===13?'King':rank===12?'Queen':rank===11?'Jack':rank;el.setAttribute('aria-label',`Card ${i+1}: ${label} of ${['spades','diamonds','clubs','hearts'][Math.floor(id/13)]}. Click to use a saved replacement.`);el.querySelector('.slot').textContent=String(i+1);el.style.left=`${i*72+13}px`;el.classList.toggle('match',r.indices.includes(i));el.dataset.slot=i;el.style.setProperty('--slot',i);
  });
 }
 $('dark-meter').hidden=world.dark<=0;$('dark-time').textContent=world.dark.toFixed(1)+'s';$('dark-meter').querySelector('i').style.transform=`scaleX(${world.dark/6})`;
 const nextToast=world.bannerTime>0?world.banner:'';if(nextToast!==toast){toast=nextToast;$('toast').textContent=toast}
 $('pause').innerHTML=(world.mode==='paused'?'Resume':'Pause')+' <kbd>P</kbd>';
 if(started&&(world.mode!==previousMode||force)){
  previousMode=world.mode;const overlay=$('overlay');overlay.hidden=['playing','drafting'].includes(world.mode);
  $('continue').hidden=true;
  if(!overlay.hidden){
   const won=world.mode==='won',final=world.stageIndex===CLEARINGS.length-1;
   $('story-eyebrow').textContent=won?(final?'CHAPTER I · THE ROAD HOME':'CLEARING '+(world.stageIndex+1)+' / '+CLEARINGS.length+' · LANTERN LIT'):world.clearing.name.toUpperCase();
   $('story-title').textContent=won?(final?'Every light leads home.':'A light in the dark.'):world.mode==='dead'?'One more hand?':'By the lantern.';
   $('story-copy').textContent=won?world.clearing.finish:world.mode==='dead'?'Take a fresh hand and try this clearing again.':'Your hand and the forest will wait right here.';
   $('begin').textContent=won?(world.practice?'Back to journey':final?'Play a new journey':'On to '+CLEARINGS[world.stageIndex+1]?.name):world.mode==='paused'?'Back to the forest':'Retry clearing';
   $('loading').textContent=won?`${world.kills} foes defeated · ${world.fallCount} falls · ${world.collected} flames returned`:'P / Esc resumes · R retries this clearing';
   if(won&&!persistedCompletion){persistedCompletion=true;persistJourney();}
  }
 }

}
function sprite(img,x,y,w,h){if(img)ctx.drawImage(img,snap(x),snap(y),snap(w),snap(h))}
function effect(name,frame,x,feet,scale=2,dir=1){const img=images.get(`${name}/${Math.min(35,Math.max(0,Math.floor(frame)))}`);if(!img)return;ctx.save();ctx.translate(snap(x),snap(feet));ctx.scale(dir,1);sprite(img,-img.width*scale/2,-img.height*scale,img.width*scale,img.height*scale);ctx.restore()}
function rect(x,y,w,h,color){ctx.fillStyle=color;ctx.fillRect(snap(x),snap(y),snap(w),snap(h))}
function circle(x,y,r,color){for(let row=-Math.floor(r/2);row<=Math.floor(r/2);row++){const half=Math.floor(Math.sqrt(Math.max(0,r*r-row*row*4))/2)*2;rect(x-half,y+row*2,half*2,2,color)}}
function text(str,x,y,size=14,color='#e3be7f'){ctx.fillStyle=color;ctx.font=`${size}px Silkscreen, monospace`;ctx.fillText(str,Math.round(x),Math.round(y))}
function polygon(points,color){ctx.fillStyle=color;ctx.beginPath();points.forEach(([x,y],i)=>i?ctx.lineTo(snap(x),snap(y)):ctx.moveTo(snap(x),snap(y)));ctx.closePath();ctx.fill()}
function diamond(x,y,r,color){polygon([[x,y-r],[x+r,y],[x,y+r],[x-r,y]],color)}
function drawEmber(e){
 // Four held poses keep the glint crisp; all shapes use the world's native pixel grid.
 const frame=reduced?0:Math.floor(visual*6+e.x)%4;
 const x=snap(e.x),y=snap(e.y+(reduced?0:[0,-2,0,2][frame]));
 const ink='#17202c',gold='#f6b63e',cream='#fff0a3',white='#ffffeb';
 // Broken rays read as a collectible halo, with a steady bright center rather than a flash.
 const reach=[18,20,18,16][frame];
 for(const side of [-1,1]){
  rect(x+side*reach-2,y-2,4,4,ink);
  rect(x+side*reach,y-2,2,2,cream);
  rect(x-2,y+side*reach-2,4,4,ink);
  rect(x-2,y+side*reach,2,2,cream);
 }
 circle(x,y,12,ink);circle(x,y,10,gold);circle(x-2,y-2,8,cream);circle(x-2,y-2,5,white);
 // Hard shadow and offset specular highlight give the orb a drawn, rounded silhouette.
 rect(x+4,y+4,4,2,'#ce7627');rect(x,y+8,4,2,'#ce7627');
 rect(x-6,y-6,4,2,white);rect(x-6,y-4,2,4,white);
 const spark=(sx,sy,r)=>{
  const points=[[0,-r],[2,-2],[r,0],[2,2],[0,r],[-2,2],[-r,0],[-2,-2]];
  polygon(points.map(([px,py])=>[sx+px,sy+py]),ink);
  rect(sx-1,sy-r+2,2,r*2-4,white);rect(sx-r+2,sy-1,r*2-4,2,white);
 };
 spark(x-16,y-14,frame<2?6:4);spark(x+16,y+10,frame>=2?6:4);
}
const cardPositions=new Map(),departing=[];
function drawDock(){
 drawBriarDock(ctx);
 const combo=evaluate(world.deck.hand),t=visual;
 for(const [id,p] of cardPositions)if(!world.deck.hand.includes(id)){departing.push({...p,id,time:t});cardPositions.delete(id)}
 world.deck.hand.forEach((id,i)=>{
  const active=world.mode==='playing'&&(hover===id||document.activeElement===cards.get(id));
  const target={x:266+i*72,y:(combo.indices.includes(i)?416:424)-(active?10:0)};
  let p=cardPositions.get(id);if(!p){const picked=world.lastPicked?.card===id?world.lastPicked:null;p=picked?{x:picked.x-cam-32,y:picked.y-80-48}:{x:960,y:540};cardPositions.set(id,p)}
  p.x+=(target.x-p.x)*.3;p.y+=(target.y-p.y)*.3;
  let rank=id%13+2;if(rank===14)rank=1;const sx=32+(Math.floor((rank-1)/3)*4+Math.floor(id/13))*32,sy=32+((rank-1)%3)*48;
  const pulse=reduced?0:Math.sin(t*2+id)*2,angle=reduced?0:(i-2)*.025+Math.sin(t*2.3+id)*.018;
  ctx.save();ctx.translate(snap(p.x+32),snap(p.y+48+pulse));ctx.rotate(angle);
  if(active){rect(-36,-52,72,104,'#101c19');rect(-34,-50,68,100,'#f6dda0')}
  ctx.drawImage(images.get('cards'),sx,sy,32,48,-32,-48,64,96);ctx.restore();
 });
 for(let i=departing.length-1;i>=0;i--){const p=departing[i],age=t-p.time;if(age>.25){departing.splice(i,1);continue}let rank=p.id%13+2;if(rank===14)rank=1;ctx.globalAlpha=1-age*4;ctx.drawImage(images.get('cards'),32+(Math.floor((rank-1)/3)*4+Math.floor(p.id/13))*32,32+((rank-1)%3)*48,32,48,snap(p.x+age*200),snap(p.y-age*220),64,96);ctx.globalAlpha=1;}
}
function draw(){
 ctx.imageSmoothingEnabled=false;ctx.clearRect(0,0,960,540);ctx.save();ctx.save();ctx.beginPath();ctx.rect(0,0,960,400);ctx.clip();ctx.translate(0,-80);
 const shake=shakeOffset(world.shakeTime,world.shakeDuration,world.shakePower,reduced);ctx.translate(shake.x,shake.y);
 const bridge=world.clearing.theme==='bridge'&&!world.arena;
 if(bridge)drawBridgeBackdrop(ctx,images,cam,visual,reduced);else drawBackdrop(ctx,images,cam,visual,reduced,world.clearing.theme);
 if(world.dark>0){ctx.fillStyle='#31184c36';ctx.fillRect(0,0,960,480)}
 ctx.save();ctx.translate(-snap(cam),0);
 if(bridge)drawBridgeArchitecture(ctx,images,world.platforms,visual,reduced);else drawTerrain(ctx,images,world.platforms,visual,reduced,world.clearing.theme);
 if(!world.arena){
  if(!bridge)drawLandmarks(ctx,images,world,visual,reduced);
  if(world.clearing.theme==='house')drawHome(ctx,images,world.collected,visual,reduced);else drawTrailGate(ctx,images,world,visual,reduced);
 }
 // Ground loot sits behind combatants; cards must never mask an enemy pose.
 for(const drop of world.cardDrops){
  const x=snap(drop.x),y=snap(drop.y-26-(reduced?0:Math.sin(visual*3+drop.id)*2)-Math.sin(Math.min(1,drop.age/.4)*Math.PI)*18);
  circle(x,y,22,'#eac77c18');rect(x-14,y-20,28,40,'#101824');rect(x-12,y-18,24,36,'#e6cc93');rect(x-10,y-16,20,32,'#713843');
  rect(x-8,y-14,16,2,'#ad6262');diamond(x,y,8,'#f6dfa5');diamond(x,y,4,'#8f424d');
  rect(x-8,y-12,2,2,'#ffeab6');rect(x+6,y+10,2,2,'#ffeab6');text('CARD',x-14,y-26,10,'#fff0bc');
 }
 for(const n of world.npcs||[]){const f=idleFrame(visual,n.x),{w,h}=characterSize(CELL,CELL),near=Math.abs(world.x-n.x)<110&&Math.abs(world.y-n.y)<80;ctx.save();ctx.translate(snap(n.x),snap(n.y));ctx.scale(world.x<n.x?-1:1,1);ctx.drawImage(images.get('cast/'+n.skin),f.x,f.y,f.w,f.h,snap(-w/2),-h,w,h);ctx.restore();if(near&&n.line){ctx.font='12px Silkscreen, monospace';const tw=snap(ctx.measureText(n.line).width+12),top=n.y-h+castTop(n.skin)*2,bx=snap(Math.max(cam+8,Math.min(cam+952-tw,n.x-tw/2)));rect(bx,top-26,tw,20,'#101226d8');text(n.line,bx+6,top-11,12,'#fff2bf');}}
 for(const e of world.enemies){const img=images.get('cast/'+e.skin);const frame=castFrame(e,world.time);ctx.save();ctx.translate(snap(e.x),snap(e.y));ctx.scale(e.face,1);const {w}=characterSize(frame.w,frame.h),h=(CELL-castTop(e.skin))*2;ctx.drawImage(img,frame.x,frame.y,frame.w,frame.h,snap(-w/2),-w,w,w);ctx.restore();rect(e.x-16,e.y-h-8,32,3,'#26322e');rect(e.x-16,e.y-h-8,32*e.hp/e.max,3,e.tough?'#bd8fe0':'#ca8072');if(e.wind>0){text(e.kind==='mage'?'CAST':e.tough?'SLAM':'!',e.x-(e.tough?20:3),e.y-h-20,12,'#ffbf80');
 if(e.kind==='mage'){diamond(e.x+e.face*18,e.y-24,8,'#172637');diamond(e.x+e.face*18,e.y-24,4,'#9ce6cf')}else rect(e.tough?e.x-90:e.x,e.y-3,e.tough?180:88*e.strikeDir,3,'#e58955');}
 if(e.state==='lunge'){rect(e.x-e.strikeDir*30,e.y-20,e.strikeDir*28,3,'#f1c17d')}
 if(e.state==='chase'&&e.hopCD<.1)text('•',e.x-2,e.y-h-18,10,'#caa16d');}
 for(const b of world.enemyShots){diamond(b.x,b.y,10,'#111d2b');diamond(b.x,b.y,7,'#8de0cf');diamond(b.x,b.y,3,'#fff0c2');}
 for(const e of world.embers)drawEmber(e);

 const clip=playerClip(world),{form,state,facing}=clip,key=form+'/'+state;
 if(key!==lastAnim){lastAnim=key;formClock=0}
 const index=playerFrame(state,world,formClock),img=images.get(`${form}/${state}/${index}`);
 ctx.save();ctx.translate(snap(world.x),snap(world.y));ctx.scale(facing,1);
 if(world.invincible>0&&world.transform<=0&&Math.floor(visual*18)%2===0)ctx.globalAlpha=.65;
 if(img){
  const {x,y}=playerOffset(form,state,img.width,img.height),{w,h}=characterSize(img.width,img.height);
  if(world.dash>0&&!reduced){for(let i=2;i>0;i--){ctx.globalAlpha=.12*(3-i);sprite(img,x-i*14,y,w,h)}ctx.globalAlpha=1}
  sprite(img,x,y,w,h);
 }
 ctx.restore();
 if(world.transform>0)effect(world.morphFrom==='light'?'FX_lighttodark':'FX_darktolight',(1-world.transform/world.morphDuration)*36,world.x,world.y,2,world.facing);
 for(const b of world.bolts){
  const shape=castShape(b.tier),dark=b.tier>=5,c=dark?'#b46bfa':'#f35a47',phase=Math.floor((1.5-b.life)*18)%3;
  ctx.save();ctx.translate(snap(b.x),snap(b.y));ctx.scale(b.dir,1);
  // Three stepped silhouettes, never a scaled-up aura sprite. Bright core and ink outline.
  polygon([[-shape.length,-8],[-22,-shape.height/2],[10,-10],[20,0],[10,10],[-22,shape.height/2],[-shape.length,8],[-42,0]],'#101226');
  polygon([[-shape.length+6,-4],[-20,-shape.height/2+4],[8,-6],[14,0],[8,6],[-20,shape.height/2-4],[-shape.length+6,4],[-32,0]],c);
  polygon([[-shape.length+14,-2],[-14,-8-phase*2],[8,0],[-14,8+phase*2],[-shape.length+14,2],[-24,0]],'#fff4cd');
  rect(-28,-4,30,8,'#fff8ec');ctx.restore();
 }
 for(const r of world.rings){const progress=1-r.life/(r.physical?.25:.45);
  if(r.physical){for(let i=-3;i<=3;i++){const x=r.x+i*12+Math.sign(i)*progress*24,y=r.y-progress*(14-Math.abs(i)*2);rect(x,y,6,4,'#978875');}continue;}
  effect(r.dark?'FX_dark':'FX_light',progress*36,r.x,r.y+22,2);
  for(let i=0;i<8;i++){const angle=i*Math.PI/4,reach=r.radius*progress;diamond(r.x+Math.cos(angle)*reach,r.y+Math.sin(angle)*reach,8,r.dark?'#cf94ff':'#ffcf77');}
 }
 for(const hit of world.impacts){const progress=1-hit.life/.25,size=(hit.amount>=14?40:20)*(progress<.2?.7+progress*2:1.1-(progress-.2)*.55);ctx.save();ctx.translate(snap(hit.x),snap(hit.y));
  const points=[];for(let i=0;i<16;i++){const r=i%2?size*.38:size;points.push([Math.cos(i*Math.PI/8)*r,Math.sin(i*Math.PI/8)*r]);}
  polygon(points,'#101226');polygon(points.map(([x,y])=>[x*.8,y*.8]),'#fff2bf');polygon(points.map(([x,y])=>[x*.42,y*.42]),'#f68152');ctx.restore();
  if(hit.amount>=14){const word=hit.knockout?'K.O.!':hit.amount>=40?'KRAK!':'WHAM!',x=snap(hit.x-34),y=snap(hit.y-54-progress*10);for(const [dx,dy] of [[-2,0],[2,0],[0,-2],[0,2]])text(word,x+dx,y+dy,24,'#101226');text(word,x,y,24,'#fff2bf');}
 }
 for(const dead of world.corpses){ctx.save();ctx.translate(snap(dead.x),snap(dead.y));ctx.scale(dead.face,1);ctx.globalAlpha=Math.min(1,dead.life/CORPSE_LIFE*3);const f=deathFrame(dead.life,CORPSE_LIFE),{w,h}=characterSize(f.w,f.h);ctx.drawImage(images.get('cast/'+dead.skin),f.x,f.y,f.w,f.h,snap(-w/2),-h,w,h);ctx.restore();}
 for(const p of world.particles)rect(p.x,p.y,3,3,'#eacd88');for(const n of world.texts)text(n.text,n.x,n.y,20,'#ffe4a2');
 // Depth foreground around the floor rather than across landing surfaces.
 ctx.restore();if(bridge)drawBridgeAtmosphere(ctx,cam,visual,reduced);else drawForeground(ctx,images,cam,world,reduced);ctx.restore();drawDock();ctx.restore();screen.imageSmoothingEnabled=false;screen.clearRect(0,0,960,540);screen.drawImage(raster,0,0,960,540);
}
function frame(now){let dt=Math.min((now-last)/1000||0, .05);last=now;if(loaded){if(started&&world.mode==='playing'){accumulator+=dt;let first=true;
  while(accumulator>=1/60){const input={axis:Number(keys.has('KeyD')||keys.has('ArrowRight'))-Number(keys.has('KeyA')||keys.has('ArrowLeft')),sword:keys.has('KeyJ')};if(first&&world.hitStop<=0){input.jump=edges.has('Space');input.jumpRelease=releaseJump;input.dash=edges.has('ShiftLeft')||edges.has('ShiftRight');input.play=edges.has('KeyK');input.drop=edges.has('KeyS')||edges.has('ArrowDown');for(let i=0;i<5;i++)if(edges.has('Digit'+(i+1)))input.replace=i;edges.clear();releaseJump=false;first=false}const before=world.time;world.step(1/60,input);const elapsed=world.time-before;visual+=elapsed;formClock+=elapsed;accumulator-=1/60}
  for(const event of world.events.splice(0))sound(event);
 }else accumulator=0;
 const target=Math.max(0,Math.min(WIDTH-960,world.x-340));cam=cameraSnap?target:cam+(target-cam)*(1-Math.exp(-dt*8));cameraSnap=false;
 draw();updateUI();for(const [id,el] of cards){let i=Number(el.dataset.slot),match=el.classList.contains('match'),active=hover===id;
 const t=visual,wiggle=reduced?0:Math.sin(t*2.3+id)*1.4+Math.sin(t*18)*Math.pow(Math.max(0,Math.sin(t*1.5+i*1.7)),12)*5;
 el.style.transform=`translateY(${(match?-7:0)+(active?-10:0)+(reduced?0:Math.sin(t*2+i)*2)}px) rotate(${reduced?0:(i-2)*2+wiggle}deg)`;el.style.zIndex=active?20:5+i;
 }}requestAnimationFrame(frame)}requestAnimationFrame(frame);
// Read-only state for checking the live game; no cheat functions are exposed.
Object.defineProperty(window,'__POKER_STATE__',{get:()=>({x:world.x,y:world.y,vx:world.vx,vy:world.vy,mode:started?world.mode:'ready',grounded:world.grounded,hand:[...world.deck.hand],hits:world.deck.hits,banked:world.deck.banked,dark:world.dark,collected:world.collected,health:world.health,practice:world.practice,stage:world.stageIndex,hitStop:world.hitStop,shakeTime:world.shakeTime,reserve:world.deck.reserve,cardDrops:world.cardDrops.map(d=>({id:d.id,x:d.x,y:d.y,blocked:d.blocked})),draft:world.deck.drafts.find(d=>d.id===world.activeDraft)?.cards??null})});
