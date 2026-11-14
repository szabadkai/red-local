// Authored architecture follows collision surfaces; see bridge-art.mjs for the pixel scenery.
import {drawBridgePixels} from './bridge-art.mjs';
import {drawMirrored} from './art.mjs';
// Coordinates are world units. The original character sprites retain their 2x scale.
const ink='#111c24';
const snap=n=>Math.round(n/2)*2;
function rect(c,x,y,w,h,color){c.fillStyle=color;c.fillRect(snap(x),snap(y),snap(w),snap(h));}
function lightPool(c,x,y,r,time,reduced,strength=.2){
 const flicker=reduced?1:.94+Math.sin(time*4+x)*.04+Math.sin(time*7)*.02;
 const g=c.createRadialGradient(x,y,2,x,y,r);g.addColorStop(0,`rgba(255,197,97,${strength*flicker})`);g.addColorStop(.35,`rgba(244,165,69,${strength*.45*flicker})`);g.addColorStop(1,'rgba(241,160,65,0)');c.fillStyle=g;c.fillRect(x-r,y-r,r*2,r*2);
}
const DEER=['x.x...x.x','.x.x.x.x.','..x.x.x..','...xxx...','...xxx...','....x....','...xxx...','...x.x...'];
function banner(c,x,y,time,reduced){
 x=snap(x);y=snap(y);rect(c,x-4,y-4,40,4,'#b69565');rect(c,x-4,y-4,4,4,'#7a5c3a');rect(c,x+32,y-4,4,4,'#7a5c3a');
 const sway=reduced?0:Math.sin(time*1.7+x);
 for(let col=0;col<16;col++){
  const dx=Math.round(sway*col/16*2)*2/2,len=col<8?56-col*2:42+col*2-14;
  rect(c,x+col*2+dx,y,2,len,col<2||col>13?'#4a1621':col%5===0?'#5e1a28':'#7a2230');
  rect(c,x+col*2+dx,y+len-2,2,2,'#4a1621');
 }
 DEER.forEach((row,j)=>[...row].forEach((ch,i)=>{if(ch==='x')rect(c,x+7*2+(i-4)*2+Math.round(sway)*2,y+10+j*2,2,2,'#d9b98a')}));
}
function lamp(c,x,y,time,reduced){
 rect(c,x,y-54,4,54,'#342c2a');rect(c,x,y-56,28,3,'#a28c65');rect(c,x+23,y-53,2,13,'#75674d');
 lightPool(c,x+24,y-27,65,time,reduced,.26);
 rect(c,x+15,y-42,20,28,ink);rect(c,x+18,y-39,14,22,'#e6a14e');rect(c,x+21,y-36,7,16,'#ffe2a1');
 rect(c,x+23,y-39,2,23,'#64533d');rect(c,x+13,y-44,24,3,'#b18a51');rect(c,x+13,y-15,24,3,'#9a784b');
}
export function drawBridgeBackdrop(c,images,cam,time,reduced){
 const offset=reduced?0:cam;
 const bg=images.get('concept-bridge-distance-v1')||images.get('concept-forest');
 drawMirrored(c,bg,offset*.12+60,35,1260,470);
 // A separate veil gives atmospheric separation without flattening the architecture.
 const fog=c.createLinearGradient(0,230,0,510);fog.addColorStop(0,'#152b3300');fog.addColorStop(1,'#10212c9c');c.fillStyle=fog;c.fillRect(0,80,960,440);
}
// The falls pour behind each bridge's arches (world space, under the cached masonry).
function falls(c,x0,time,reduced){
 const t=reduced?0:time;
 rect(c,x0,372,520,188,'#1d3a44');
 for(let x=x0;x<x0+520;x+=6){
  const n=(x*37)%11;rect(c,x,372,4,188,n>6?'#5d93a0':'#3f6f7c');
  for(let k=0;k<3;k++){const y=372+((k*83+n*19+t*(90+n*6))%188);rect(c,x,y,2,12+n,n>4?'#cfe8ea':'#93c2c8');}
 }
 for(let x=x0;x<x0+520;x+=4){const y=468+Math.round(Math.sin(x*.3+t*6)*2/2)*2;rect(c,x,y,4,4,'#e3f1f0');rect(c,x+2,y+4,2,2,'#a9d0d3');}
}
export function drawBridgeArchitecture(c,images,platforms,time,reduced){
 const bridges=platforms.filter(p=>p.kind==='bridge');
 for(const b of bridges)falls(c,b.x+70,time,reduced);
 drawBridgePixels(c,platforms,images);
 for(const b of bridges)banner(c,b.x+b.w*.48,b.y+18,time,reduced);
 for(const [x,y] of [[100,420],[730,360],[985,420],[1560,420],[1800,420],[2220,300],[2520,420],[3190,360],[3445,420],[4120,420],[4620,300]])lamp(c,x,y,time,reduced);
 rect(c,1874,316,4,104,'#342c2a');rect(c,1866,312,20,4,'#a28c65');banner(c,1864,320,time,reduced);
 lightPool(c,52,250,110,time,reduced,.16);lightPool(c,4510,488,60,time,reduced,.2);
}
export function drawBridgeAtmosphere(c,cam,time,reduced){
 // Sparse airborne leaves and sparks. Never resemble collectible ember halos.
 for(let i=0;i<18;i++){
  const t=reduced?0:time,x=((i*149-cam*.65+t*(5+i%3))%1100+1100)%1100-70;
  const y=105+(i*73)%330+(reduced?0:Math.sin(t+i)*10);
  rect(c,x,y,i%3?3:6,2,i%3?'#e1bb7466':'#ae424c');
 }
 // Edge vignette, leaving the center and landing surfaces unobscured.
 const v=c.createLinearGradient(0,0,960,0);v.addColorStop(0,'#07121b55');v.addColorStop(.15,'#07121b00');v.addColorStop(.85,'#07121b00');v.addColorStop(1,'#07121b55');c.fillStyle=v;c.fillRect(0,80,960,400);
}
export function drawBriarDock(c,images){
 rect(c,0,400,960,140,'#141116');rect(c,0,400,960,2,'#a17b5b');rect(c,0,404,960,1,'#443a37');
 // One frame around the whole dock, with the corner piece flipped into each corner.
 rect(c,8,410,944,2,'#7a6555');rect(c,8,528,944,2,'#7a6555');rect(c,8,410,2,120,'#7a6555');rect(c,950,410,2,120,'#7a6555');
 const corner=images?.get('dock-corner'),branch=images?.get('dock-branch');
 c.save();c.imageSmoothingEnabled=false;
 if(corner)for(const [sx,sy] of [[1,1],[-1,1],[1,-1],[-1,-1]]){
  c.save();c.translate(sx>0?8:952,sy>0?410:530);c.scale(sx,sy);c.drawImage(corner,0,0,32,26);c.restore();
 }
 // Briar ornaments (assets/ui/dock_branch.png, 124x60) at 2x, mirrored on the right.
 if(branch){c.drawImage(branch,8,410,248,120);c.translate(960,0);c.scale(-1,1);c.drawImage(branch,8,410,248,120);}
 c.restore();
}
