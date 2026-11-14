// Soundtrack and sound effects, synthesised from note text by chip.mjs in a worker (no audio files).
import {SFX} from './sfx.mjs';
export const STAGE_TUNES=['01_lantern_wood','02_broken_crossing','03_moss_cavern','04_ruined_chapel','05_thorn_house'];
export const BOSS_TUNES=['01_boss_briar_hart','02_boss_tollkeeper','03_boss_rowan','04_boss_bell_widow','05_boss_wolf'];
export function tuneFor(world){
 const phase=world.storyPhase,stage=world.stageIndex;
 if(phase==='home'||phase==='complete'||(phase==='cleared'&&stage===STAGE_TUNES.length-1))return STAGE_TUNES[0];
 if(world.boss||phase==='inside'||phase==='garden')return BOSS_TUNES[stage];
 return STAGE_TUNES[stage];
}
export function createMusic(volume=.1,sfxVolume=.16){
 let ctx=null,track=null,paused=null,wanted='',cue='';
 const rendered=new Map(),pending=new Set(),failed=new Set();
 const worker=new Worker(new URL('./music-worker.mjs',import.meta.url),{type:'module'});
 worker.onmessage=({data})=>{
  pending.delete(data.name);
  if(!data.samples){failed.add(data.name);console.warn('music:',data.name,data.error);return;}
  rendered.set(data.name,data);if(ctx&&wanted===data.name&&track?.name!==wanted)change();
 };
 function preload(name,text){
  if(!name||rendered.has(name)||pending.has(name)||failed.has(name))return;
  pending.add(name);worker.postMessage({name,text});
 }
 for(const [name,{text}] of Object.entries(SFX))preload(name,text);
 function unlock(){if(!ctx)ctx=new AudioContext();if(ctx.state==='suspended')ctx.resume();}
 function source(name,level){
  const data=rendered.get(name),node=ctx.createBufferSource(),gain=ctx.createGain();
  if(!data.buffer){data.buffer=ctx.createBuffer(1,data.samples.length,data.rate);data.buffer.copyToChannel(data.samples,0);}
  node.buffer=data.buffer;gain.gain.value=level;node.connect(gain);gain.connect(ctx.destination);return {node,gain};
 }
 function sfx(name,when=0){
  if(!rendered.has(name))return 0;
  unlock();const {node}=source(name,sfxVolume*SFX[name].gain);node.start(when);return node.buffer.duration;
 }
 function begin(name,when,fade,offset=0){
  const {node,gain}=source(name,volume);node.loop=true;
  if(fade){gain.gain.setValueAtTime(0,when);gain.gain.linearRampToValueAtTime(volume,when+fade);}
  node.start(when,offset);track={name,node,gain,start:when-offset,beat:60/rendered.get(name).tempo};
 }
 function end(when){
  const {node,gain}=track,now=ctx.currentTime;
  gain.gain.cancelScheduledValues(now);gain.gain.setValueAtTime(gain.gain.value,now);gain.gain.linearRampToValueAtTime(0,when);
  node.stop(when+.05);track=null;
 }
 function change(){
  const name=wanted,now=ctx.currentTime;
  if(!track){const resume=paused?.name===name;begin(name,now,resume?.2:.6,resume?paused.offset:0);paused=null;return;}
  if(cue==='victory'){
   // Boss beaten: cut the fight music, play the fanfare, then bring the stage theme in under its tail.
   end(now+.3);const length=sfx('victory',now+.3);begin(name,now+.3+Math.max(0,length-.4),1.5);
  }else if(BOSS_TUNES.includes(name)){
   // Into a fight: the old tune stops on its next beat and the boss theme enters there, under a hit.
   let wait=track.beat-Math.max(0,now-track.start)%track.beat;if(wait<.12)wait+=track.beat;
   end(now+wait);sfx('boss_intro',now+wait);begin(name,now+wait,0);
  }else{end(now+1.2);begin(name,now+.6,1.2);}
 }
 // Call every frame with the tune that should be sounding. '' fades out; the same tune later resumes where it was.
 function play(name,how=''){
  if(!name){
   wanted='';
   if(track){const now=ctx.currentTime;paused={name:track.name,offset:Math.max(0,now-track.start)%track.node.buffer.duration};end(now+.25);}
   return;
  }
  unlock();cue=how;
  if(name===wanted&&(track||pending.has(name)))return;
  wanted=name;
  if(track?.name===name)return;
  if(rendered.has(name))change();else preload(name);
 }
 return {play,preload,unlock,sfx};
}
