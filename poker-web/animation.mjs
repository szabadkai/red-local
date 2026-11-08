export const PLAYER_CLIPS={idle_blink:[3,'idle_blink'],run:[10,'run'],jump:[4,'jump'],fall:[4,'fall'],dash:[4,'dash'],attack1:[10,'attack1_'],attack3:[11,'attack3_'],transform:[38,'transform']};
export function playerClip(w){
 const form=w.dark>0?'dark':'light';
 if(w.attack>0)return {form:w.attackForm,state:'attack1',facing:w.attackFacing};
 if(w.dash>0)return {form,state:'dash',facing:w.facing};
 if(w.transform>0&&w.morphPose)return {form:w.morphFrom,state:'transform',facing:w.morphFacing};
 if(w.cast>0)return {form:w.castForm,state:'attack3',facing:w.castFacing};
 return {form,state:!w.grounded?(w.vy<0?'jump':'fall'):Math.abs(w.vx)>10?'run':'idle_blink',facing:w.facing};
}
export function playerFrame(state,w,age){
 if(state==='transform')return Math.min(37,Math.floor((1-w.transform/w.morphDuration)*38));
 if(state==='attack1'){
  const elapsed=.32-w.attack;
  // The original sheet has its contact slash at frame 1, followed by recovery poses.
  return elapsed<.10?0:elapsed<.15?1:Math.min(9,2+Math.floor((elapsed-.15)/.17*8));
 }
 if(state==='attack3')return Math.min(10,1+Math.floor(Math.max(0,.36-w.cast-.06)/.30*10));
 if(state==='dash')return Math.min(3,Math.floor((1-w.dash/.14)*4));
 if(state==='idle_blink'){
  const blink=age%3.4,open=w.dark>0?2:0,closed=2-open;
  return blink<3.08?open:blink<3.16?1:blink<3.24?closed:blink<3.32?1:open;
 }
 if(state==='run')return Math.floor(age*(w.dark>0?18:16))%10;
 // Rise and fall settle into their final pose instead of restarting the takeoff repeatedly.
 return Math.min(3,Math.floor(age*16));
}
