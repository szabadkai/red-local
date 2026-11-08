// Character pixels retain a 2x world pitch on the 960x540 presentation canvas.
export const PIXEL=2;
export const characterSize=(width,height)=>({w:width*PIXEL,h:height*PIXEL});
export const snap=n=>Math.round(n/PIXEL)*PIXEL;
// Anatomical pivots in source pixels, excluding transparent padding and spell trails.
const pivots={
 light:{idle_blink:[8,18],run:[10,21],jump:[7,25],fall:[8,30],dash:[11,19],attack1:[18,27],attack3:[18,27],transform:[12,60]},
 dark:{idle_blink:[12,18],run:[13,22],jump:[12,27],fall:[9,37],dash:[16,21],attack1:[26,33],attack3:[26,33],transform:[12,65]}
};
export function playerAnchor(form,state,width){return pivots[form]?.[state]?-pivots[form][state][0]*PIXEL:-width*PIXEL/2;}
export function playerOffset(form,state,width,height){return {x:playerAnchor(form,state,width),y:-(pivots[form]?.[state]?.[1]??height)*PIXEL};}
export function enemyFrame(e,time){
 if(e.air)return e.vy<0?150:214;
 if(e.state==='windup')return 86;
 if(e.state==='lunge')return 246;
 if(e.state==='stagger')return 118;
 if(e.state==='idle'||e.state==='recover')return [22,54,86,54][Math.floor(time*4+e.id)%4];
 return [150,182,214,246][Math.floor(e.walk*10)%4];
}
// Original atlas frames: no stretching a small enemy up to the orc's size.
export function enemySprite(e,time){
 const defs={scout:{y:202,w:15,h:22,x:129},runner:{y:235,w:15,h:21,x:129},mage:{y:138,w:15,h:22,x:128},guard:{y:70,w:15,h:26,x:128}};
 const def=defs[e.kind||(e.tough?'brute':'scout')];if(!def)return {x:enemyFrame(e,time),y:386,w:21,h:30};
 const moving=['chase','patrol','lunge','jump','drop'].includes(e.state);
 const frame=e.state==='windup'?2:e.state==='stagger'?3:Math.floor((moving?e.walk*10:time*4)+e.id)%4;
 return {x:def.x+(moving?64:0)+frame*16,y:def.y,w:def.w,h:def.h};
}
export function castShape(tier){return {length:tier>=5?94:tier>=3?76:58,height:tier>=5?54:tier>=1?34:26};}
export function shakeOffset(time,duration,power,reduced=false){
 if(reduced||time<=0||duration<=0)return {x:0,y:0};
 const steps=[[1,0],[-1,.5],[.5,-1],[-.5,.5],[1,-.5],[-1,0]];
 const [x,y]=steps[Math.floor((duration-time)*60)%steps.length],strength=power*(time/duration)**2;
 return {x:snap(x*strength),y:snap(y*strength)};
}
