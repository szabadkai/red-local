// Authored architecture follows collision surfaces; atlas openings retain their alpha.
// Coordinates are world units. The original character sprites retain their 2x scale.
const crops={tower:[24,30,550,590],oak:[620,20,640,600],arch:[14,710,600,450],shrine:[640,740,610,410]};
const ink='#111c24',stone='#4c5554',light='#b5b285',moss='#859050';
const snap=n=>Math.round(n);
function rect(c,x,y,w,h,color){c.fillStyle=color;c.fillRect(snap(x),snap(y),snap(w),snap(h));}
function poly(c,points,color){c.fillStyle=color;c.beginPath();points.forEach(([x,y],i)=>i?c.lineTo(snap(x),snap(y)):c.moveTo(snap(x),snap(y)));c.closePath();c.fill();}
function asset(c,images,name,x,y,w,h,alpha=1){
 const image=images.get('concept-bridge-atlas-v1');if(!image)return;
 c.save();c.globalAlpha=alpha;c.drawImage(image,...crops[name],snap(x),snap(y),snap(w),snap(h));c.restore();
}
function lightPool(c,x,y,r,time,reduced,strength=.2){
 const flicker=reduced?1:.94+Math.sin(time*4+x)*.04+Math.sin(time*7)*.02;
 const g=c.createRadialGradient(x,y,2,x,y,r);g.addColorStop(0,`rgba(255,197,97,${strength*flicker})`);g.addColorStop(.35,`rgba(244,165,69,${strength*.45*flicker})`);g.addColorStop(1,'rgba(241,160,65,0)');c.fillStyle=g;c.fillRect(x-r,y-r,r*2,r*2);
}
function vine(c,x,y,length,seed){
 for(let i=0;i<length;i+=7){const dx=Math.sin(i*.12+seed)*5;rect(c,x+dx,y+i,2,9,'#40302d');
  poly(c,[[x+dx,y+i],[x+dx-9,y+i-3],[x+dx-5,y+i+5],[x+dx,y+i+6]],i%3?'#913942':'#c25046');}
}
function ledge(c,p){
 const {x,y,w}=p;
 // A continuous, unambiguous landing lip; irregular material hangs below it.
 rect(c,x,y,w,2,light);rect(c,x,y+2,w,3,moss);
 for(let i=3;i<w-4;i+=11){const n=(i*17+p.id*13)%19;rect(c,x+i,y+3,2+n%4,2+n/4,'#687346');if(n>10)rect(c,x+i,y-3,2,4,'#b9b278');}
}
function masonry(c,images,p,depth){
 const {x,y,w}=p;rect(c,x,y,w,depth,ink);
 c.save();c.beginPath();c.rect(x,y,w,depth);c.clip();
 const atlas=images.get('concept-bridge-atlas-v1');
 for(let bx=x;bx<x+w;bx+=68)for(let by=y;by<y+depth;by+=144){
  c.drawImage(atlas,45,900,110,230,bx,by,70,146);
 }
 const shade=c.createLinearGradient(0,y,0,y+depth);shade.addColorStop(0,'#101d2400');shade.addColorStop(1,'#101d2488');c.fillStyle=shade;c.fillRect(x,y,w,depth);c.restore();
 ledge(c,p);
}
function branch(c,images,p,trunk){
 const {x,y,w}=p;
 const bough=images.get('concept-bridge-bough-v1');
 // Lower limbs join the tree; upper boughs sit directly on the atlas oak's branch.
 if(bough&&(p.kind==='root'||p.id===7||p.id===13)){
  const sx=x+w-20,sy=y+12,dx=trunk-sx,dy=55;
  c.save();c.translate(sx,sy);c.rotate(Math.atan2(dy,dx));
  c.drawImage(bough,20,267,1730,280,0,-3,Math.hypot(dx,dy),24);c.restore();
 }
 if(bough)c.drawImage(bough,20,267,1730,280,x,y-3,w,Math.max(38,w*.19));
 rect(c,x+2,y,w-4,2,'#a3a56c');
}
function banner(c,x,y,time,reduced){
 rect(c,x-3,y-3,40,3,'#b69565');
 const sway=reduced?0:Math.round(Math.sin(time*1.7+x)*2);
 poly(c,[[x,y],[x+32,y],[x+32+sway,y+58],[x+16,y+51],[x+sway,y+60]],'#642e3b');
 rect(c,x+3,y+3,2,45,'#b76b55');rect(c,x+27,y+3,2,45,'#b76b55');
 poly(c,[[x+16,y+13],[x+18,y+23],[x+25,y+18],[x+21,y+27],[x+17,y+30],[x+17,y+40],[x+14,y+40],[x+14,y+29],[x+8,y+23],[x+7,y+17],[x+14,y+23]],'#cdb37b');
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
 c.drawImage(bg,-offset*.12-60,35,1260,470);
 // A separate veil gives atmospheric separation without flattening the architecture.
 const fog=c.createLinearGradient(0,230,0,510);fog.addColorStop(0,'#152b3300');fog.addColorStop(1,'#10212c9c');c.fillStyle=fog;c.fillRect(0,80,960,440);
 // Water is behind the open arches, so the ravine reads through the real openings.
 for(let i=0;i<12;i++){
  const x=520-offset*.22+i*5,y=260+((i*43+(reduced?0:time*35))%230);
  rect(c,x,y,2,30+i%3*11,'#91bdc221');
 }
 // Distant silhouettes move independently of the nearest architecture.
 asset(c,images,'oak',780-offset*.34,-70,460,500,.25);
 asset(c,images,'tower',1070-offset*.28,160,190,260,.22);
}
export function drawBridgeArchitecture(c,images,platforms,time,reduced){
 // Background pieces at gameplay depth, always behind the actors.
 asset(c,images,'tower',-35,88,275,332);
 asset(c,images,'oak',435,24,560,480);
 asset(c,images,'tower',1015,118,240,302);
 asset(c,images,'oak',1230,24,560,480);
 asset(c,images,'oak',1990,15,470,500);
 asset(c,images,'shrine',305,345,170,114);
 asset(c,images,'shrine',1695,273,220,148);
 for(const p of platforms){
  if(p.kind==='bridge'){
   const count=Math.ceil(p.w/330),w=p.w/count;
   for(let i=0;i<count;i++)asset(c,images,'arch',p.x+i*w-3,p.y-64,w+6,250);
   ledge(c,p);
   banner(c,p.x+p.w*.48,p.y+14,time,reduced);
  }else if(p.kind==='branch'||p.kind==='root'){
   branch(c,images,p,p.x<900?915:p.x<1700?1715:2360);
  }else if(p.ground){
   masonry(c,images,p,140);for(let i=0;i<Math.floor(p.w/130);i++)vine(c,p.x+35+i*130,p.y+8,42+i%3*13,i);
  }else if(p.kind==='lower'){
   masonry(c,images,p,40);
  }else{
   // Ruined wall corbels connect raised stone platforms to their foundations.
   masonry(c,images,{...p,x:p.x+Math.max(0,p.w-55),w:42,y:p.y+12},Math.max(24,430-p.y));
   masonry(c,images,p,20);vine(c,p.x+12,p.y+12,42,p.id);
  }
 }
 for(const [x,y] of [[100,420],[730,360],[985,420],[1560,420],[2220,300]])lamp(c,x,y,time,reduced);
 banner(c,1835,322,time,reduced);
 lightPool(c,115,275,120,time,reduced,.18);lightPool(c,396,428,48,time,reduced,.25);
 lightPool(c,1148,282,90,time,reduced,.17);lightPool(c,1835,365,62,time,reduced,.24);
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
export function drawBriarDock(c){
 rect(c,0,400,960,140,'#171b23');rect(c,0,400,960,2,'#a17b5b');rect(c,0,404,960,1,'#443a37');
 for(const flip of [false,true]){
  c.save();if(flip){c.translate(960,0);c.scale(-1,1);}
  poly(c,[[0,536],[35,511],[66,515],[95,492],[130,500],[170,469],[210,474],[172,475],[132,506],[96,498],[68,521],[36,517],[0,540]],'#79644f');
  for(let i=0;i<8;i++){const x=18+i*24,y=526-i*7;poly(c,[[x,y],[x-9,y-14],[x+1,y-9],[x+5,y-19],[x+10,y-7],[x+7,y+1]],i%2?'#7b3441':'#9d4148');}
  c.restore();
 }
}
