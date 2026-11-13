// Local-only review fixture. Excluded from the standalone build.
import {world,enterWorld} from '../game.mjs';
import {SCENES} from '../story-data.mjs';
import {bossInput} from './support/story-player.mjs';
const panel=document.createElement('aside');
panel.style='position:fixed;bottom:0;left:0;z-index:999;background:#10202b;padding:6px;font:12px monospace;display:flex;gap:8px;align-items:center';
panel.innerHTML='<span>LOCAL REVIEW · practice only</span><select id="review-scene"></select><button id="review-open">Open scene</button><button id="review-capture">Record Hart demo · 18s</button><a id="review-download" hidden>Download recording</a><span id="review-status"></span>';
document.body.append(panel);
const select=panel.querySelector('select');
const phases={prologue:[0,'trail'],stranger:[0,'trail'],hartIntro:[0,'boss'],hartOutro:[0,'cleared'],pip:[1,'trail'],tollIntro:[1,'boss'],tollOutro:[1,'cleared'],cavern:[2,'trail'],rowanIntro:[2,'boss'],rowanOutro:[2,'cleared'],chapel:[3,'trail'],widowIntro:[3,'boss'],widowOutro:[3,'cleared'],house:[4,'trail'],wolfIntro:[4,'boss'],swallowed:[4,'inside'],inside:[4,'inside'],garden:[4,'garden'],breakfast:[4,'cleared'],epilogue:[4,'home']};
for(const [id,scene] of Object.entries(SCENES)){const option=document.createElement('option');option.value=id;option.textContent=scene.title;select.append(option);}
panel.querySelector('#review-open').onclick=()=>{
 const [stage,phase]=phases[select.value];world.reset(stage,{phase,seen:[],dialogue:{id:select.value,index:0}});world.practice=true;world.bossPractice=true;enterWorld();
};
let recorder,frames=[],reviewKeys=new Set(),until=0,output,oc,stream,recordedUrl,jumpUntil=0;
const keyCodes={axisRight:'KeyD',axisLeft:'KeyA',sword:'KeyJ',jump:'Space',dash:'ShiftLeft'};
function sendKeys(next){
 for(const code of reviewKeys)if(!next.has(code))document.getElementById('stage').dispatchEvent(new KeyboardEvent('keyup',{code,bubbles:true}));
 for(const code of next)if(!reviewKeys.has(code))document.getElementById('stage').dispatchEvent(new KeyboardEvent('keydown',{code,bubbles:true}));
 reviewKeys=next;
}
function captureFrame(now){
 if(!recorder||recorder.state!=='recording')return;
 if(now>=until){sendKeys(new Set());recorder.stop();if(world.mode==='playing')world.mode='paused';return;}
 if(world.mode==='drafting')world.chooseDraft(0);
 const input=world.mode==='playing'?bossInput(world):{},next=new Set();
 if(input.axis>0)next.add(keyCodes.axisRight);if(input.axis<0)next.add(keyCodes.axisLeft);
 if(input.jump)jumpUntil=now+380;
 if(input.sword)next.add(keyCodes.sword);if(now<jumpUntil)next.add(keyCodes.jump);if(input.dash)next.add(keyCodes.dash);sendKeys(next);
 oc.drawImage(document.getElementById('game'),0,0);
 oc.fillStyle='#101b24';oc.fillRect(260,16,440,70);oc.fillStyle='#f0d4a2';oc.font='16px Silkscreen';oc.textAlign='center';
 oc.fillText('THE BRIAR HART',480,39);oc.fillStyle='#41343c';oc.fillRect(290,48,380,8);oc.fillStyle='#c46e79';oc.fillRect(290,48,380*Math.max(0,world.boss?.hp||0)/80,8);
 oc.fillStyle='#f0d4a2';oc.font='10px Silkscreen';oc.fillText(document.getElementById('boss-tell').textContent,480,74);
 oc.fillStyle='#101b24';oc.fillRect(10,12,156,35);oc.fillStyle='#f0d4a2';oc.fillText('HEALTH '+world.health+' / 5',88,34);
 panel.querySelector('#review-status').textContent='Recording '+Math.ceil((until-now)/1000)+'s';requestAnimationFrame(captureFrame);
}
panel.querySelector('#review-capture').onclick=()=>{
 if(!document.getElementById('begin').disabled&&(!recorder||recorder.state==='inactive')){
  world.practiceDeal(10);enterWorld();frames=[];
  output=document.createElement('canvas');output.width=960;output.height=540;oc=output.getContext('2d');oc.imageSmoothingEnabled=false;
  stream=output.captureStream(30);const mime=['video/webm;codecs=vp9','video/webm;codecs=vp8','video/mp4'].find(m=>MediaRecorder.isTypeSupported(m));
  recorder=new MediaRecorder(stream,mime?{mimeType:mime}:undefined);
  recorder.ondataavailable=e=>{if(e.data.size)frames.push(e.data);};
  recorder.onstop=()=>{
   stream.getTracks().forEach(t=>t.stop());if(recordedUrl)URL.revokeObjectURL(recordedUrl);
   const blob=new Blob(frames,{type:recorder.mimeType});recordedUrl=URL.createObjectURL(blob);
   const a=panel.querySelector('#review-download');a.href=recordedUrl,jumpUntil=0;a.download='story-hart-demo.'+(recorder.mimeType.includes('mp4')?'mp4':'webm');a.hidden=false;
   panel.querySelector('#review-status').textContent='Recorded. Automated inputs, normal combat.';
  };
  recorder.start();until=performance.now()+18000;requestAnimationFrame(captureFrame);
 }
};
