import {snap} from './art.mjs';
import {periodicPixels,compatibleTile,TERRAIN_TILE_SIZE} from './tiles.mjs';

const SCENERY_PALETTE=['101820','17252b','20343a','2b4449','38585b','477077','5b8989','83aaa0','b4c6ac','ece0ad','262128','3a2b32','543840','73424a','99504f','b76955','495241','687356','96976c','c5ad7a']
 .map(hex=>[0,2,4].map(i=>parseInt(hex.slice(i,i+2),16)));
function crispScenery(context,w,h){
 const pixels=context.getImageData(0,0,w,h),data=pixels.data,cache=new Map();
 let indices=new Int16Array(w*h);
 for(let i=0;i<indices.length;i++){
  const p=i*4;if(data[p+3]<160){indices[i]=-1;continue;}
  const key=(data[p]<<16)|(data[p+1]<<8)|data[p+2];let nearest=cache.get(key);
  if(nearest===undefined){
   let distance=Infinity;
   SCENERY_PALETTE.forEach(([r,g,b],index)=>{const d=(r-data[p])**2+1.4*(g-data[p+1])**2+(b-data[p+2])**2;if(d<distance){distance=d;nearest=index}});
   cache.set(key,nearest);
  }indices[i]=nearest;
 }
 // Merge isolated flecks into existing solid color clusters, never blur or
 // dither. Preserve the silhouette by excluding transparent neighbors.
 for(let pass=0;pass<2;pass++){
  const next=indices.slice();
  for(let y=1;y<h-1;y++)for(let x=1;x<w-1;x++){
   const i=y*w+x,current=indices[i];if(current<0)continue;
   const counts=new Uint8Array(SCENERY_PALETTE.length);
   for(const d of [-w-1,-w,-w+1,-1,1,w-1,w,w+1])if(indices[i+d]>=0)counts[indices[i+d]]++;
   if(counts[current]>1)continue;
   let best=current;for(let n=0;n<counts.length;n++)if(counts[n]>counts[best])best=n;
   if(counts[best]>=3)next[i]=best;
  }indices=next;
 }
 for(let i=0;i<indices.length;i++){
  const p=i*4,index=indices[i];data[p+3]=index<0?0:255;
  if(index>=0){const [r,g,b]=SCENERY_PALETTE[index];data[p]=r;data[p+1]=g;data[p+2]=b;}
 }context.putImageData(pixels,0,0);
}
// Every prepared image is native logical-pixel art at render time. Source files
// stay intact; palette conversion and edge matching happen once during loading.
function surface(w,h){const c=document.createElement('canvas');c.width=w;c.height=h;return c;}
function finishSurface(canvas,periodic='',profile='mean'){
 const context=canvas.getContext('2d'),{width:w,height:h}=canvas;
 if(periodic){const p=context.getImageData(0,0,w,h);p.data.set(periodicPixels(p.data,w,h,periodic,Math.min(24,Math.floor(w/16)),profile));context.putImageData(p,0,0);}
 crispScenery(context,w,h);return canvas;
}
export function prepareScenery(images){
 for(const [name,w,h] of [['forest',560,244],['thorn-house',560,244],['oaks',860,244],['stone',96,96],['moss-cavern-v2',768,256],['ruined-chapel-v2',768,256],['masonry-v2',96,96]]){
  const canvas=surface(w,h),context=canvas.getContext('2d');context.imageSmoothingEnabled=false;
  const image=images.get('concept-'+name);
  if(name==='masonry-v2'){
   const inset=Math.round(image.width*.055);context.drawImage(image,inset,0,image.width-inset*2,image.height,0,0,w,h);
  }else context.drawImage(image,0,0,w,h);
  images.set('paint-'+name,finishSurface(canvas,name==='masonry-v2'?'xy':name.endsWith('-v2')?'x':'',name==='masonry-v2'?'interior':'mean'));
 }
 const atlas=images.get('concept-interior-props-v2');
 // The atlas cells are independent objects, not scaled instances at draw time.
 // Each is rasterized to its authored game size once, preserving alpha holes.
 for(const [index,name,w,h] of [[0,'root-column',64,96],[1,'hanging-roots',128,112],[2,'moss-rock',64,56],[3,'blue-mushrooms',40,40],[4,'chapel-column',64,112],[5,'ruined-arch',128,128],[6,'carved-rubble',64,48],[7,'candle-shrine',40,64]]){
  const canvas=surface(w,h),context=canvas.getContext('2d');context.imageSmoothingEnabled=false;
  context.drawImage(atlas,index%4*atlas.width/4,Math.floor(index/4)*atlas.height/2,atlas.width/4,atlas.height/2,0,0,w,h);
  images.set('prop-'+name,finishSurface(canvas));
 }
 prepareTerrain(images);
}
function prepareTerrain(images){
 const source=images.get('paint-masonry-v2'),size=TERRAIN_TILE_SIZE;
 for(const theme of ['cave','chapel']){
  const raw=[];
  for(let i=0;i<9;i++){
   const canvas=surface(size,size),c=canvas.getContext('2d');c.drawImage(source,0,0);
   const pixels=c.getImageData(0,0,size,size);
   // Material tint, followed by the same palette quantization as the scenery.
   for(let p=0;p<pixels.data.length;p+=4){const d=pixels.data,tone=.92+i*.02;
    d[p]*=tone;d[p+1]*=tone;d[p+2]*=tone;
    if(theme==='cave'){d[p]*=.69;d[p+1]*=.88;d[p+2]=d[p+2]*.93+8;}
    else{d[p]*=.84;d[p+1]*=.8;d[p+2]=d[p+2]*.92+9;}
   }
   raw.push(pixels);
  }
  const canonical=raw[4].data;
  const tiles=surface(size*9,size),tc=tiles.getContext('2d');
  raw.forEach((p,i)=>{p.data.set(compatibleTile(p.data,canonical,size,size));const c=surface(size,size),cc=c.getContext('2d');cc.putImageData(p,0,0);finishSurface(c);tc.drawImage(c,i*size,0);});
  images.set('tiles-'+theme,tiles);
 }
}
const rect=(ctx,x,y,w,h,color)=>{ctx.fillStyle=color;ctx.fillRect(snap(x),snap(y),snap(w),snap(h))};
export function drawProp(ctx,images,name,x,feet,flip=false){
 const image=images.get('prop-'+name);if(!image)return;
 ctx.save();ctx.translate(snap(x),snap(feet));if(flip)ctx.scale(-1,1);
 ctx.drawImage(image,snap(-image.width),-image.height*2,image.width*2,image.height*2);ctx.restore();
}
function drawInterior(ctx,images,cam,time,reduced,theme){
 const cave=theme==='cave',background=images.get(cave?'paint-moss-cavern-v2':'paint-ruined-chapel-v2'),width=background.width*2;
 rect(ctx,0,48,960,488,cave?'#101f2b':'#211f31');
 for(let x=-(cam*.12)%width-width;x<960;x+=width)ctx.drawImage(background,snap(x),32,width,background.height*2);
 // Midground silhouettes pass independently behind combat. A long repeat
 // interval and alternating props avoid the previous wallpaper-like columns.
 const period=2048,offset=-(cam*.3)%period;
 ctx.globalAlpha=.6;
 for(let base=offset-period;base<960;base+=period){
  drawProp(ctx,images,cave?'root-column':'chapel-column',base+164,444);
  drawProp(ctx,images,cave?'moss-rock':'ruined-arch',base+760,446,true);
  drawProp(ctx,images,cave?'root-column':'chapel-column',base+1390,444,true);
  drawProp(ctx,images,cave?'blue-mushrooms':'carved-rubble',base+1870,448);
 }
 ctx.globalAlpha=1;
 const near=-(cam*.54)%1536;
 for(let base=near-1536;base<960;base+=1536){
  if(cave){drawProp(ctx,images,'hanging-roots',base+90,222);drawProp(ctx,images,'hanging-roots',base+930,190,true);}
  else{drawProp(ctx,images,'ruined-arch',base+160,202);}
 }
 for(let i=0;i<12;i++){
  const t=reduced?0:time,x=((i*173-cam*.32+t*3)%1000+1000)%1000;
  rect(ctx,x,150+i*23%270,2,2,cave?'#477580':'#8b7a8c');
 }
}
export function drawBackdrop(ctx,images,cam,time,reduced,theme){
 const viewCam=reduced?0:cam;
 if(theme==='cave'||theme==='chapel'){drawInterior(ctx,images,viewCam,time,reduced,theme);return;}
 ctx.drawImage(images.get(theme==='house'?'paint-thorn-house':'paint-forest'),snap(-viewCam*.1),48,1120,488);
 rect(ctx,-12,48,984,450,theme==='house'?'#1e102b60':theme==='bridge'?'#0b273d38':'#071d2428');
 // Separate transparent tree sheets move at their own depths. The distant
 // painting, low woodland and oak canopy are three independent image planes.
 const woods=images.get('forest5');
 if(woods){
  const width=woods.width*2,offset=-(viewCam*.24)%width;ctx.globalAlpha=.35;
  for(let x=offset-width;x<960;x+=width)ctx.drawImage(woods,snap(x),500-woods.height*2,width,woods.height*2);
  ctx.globalAlpha=1;
 }
 const oak=images.get('paint-oaks');
 if(oak){
  // The framing sheet is not tileable: keep both cropped edges outside the
  // camera throughout the entire clearing instead of exposing a repeat seam.
  ctx.drawImage(oak,snap(-viewCam*.46),48,1720,488);
 }
 // Quiet motes and drifting scarlet leaves add depth without imitating pickups.
 for(let i=0;i<20;i++){
  const t=reduced?0:time,x=((i*137-viewCam*.32+t*(3+i%3))%1020+1020)%1020-30,y=120+(i*67)%260;
  ctx.globalAlpha=.2+(i%3)*.08;rect(ctx,x,y+(reduced?0:Math.sin(t*.7+i)*9),i%4===0?6:2,i%4===0?2:2,i%4===0?'#d16e58':'#ffe4a0');
 }ctx.globalAlpha=1;
}
export function drawForeground(ctx,images,cam,world,reduced){
 // The opening forest is already framed by its oak canopy and undergrowth.
 // Repeated oval bushes below the ground line look detached from that scenery.
 if(reduced||world.clearing.theme==='wood')return;
 if(['cave','chapel'].includes(world.clearing.theme)){
  const offset=-(cam*1.12)%640;
  for(let x=offset-640;x<960;x+=640){
   const left=cam+x-64;if(!world.platforms.some(p=>p.ground&&left>=p.x&&left+128<=p.x+p.w))continue;
   drawProp(ctx,images,world.clearing.theme==='cave'?'moss-rock':'carved-rubble',x,530);
  }
  return;
 }
 // Native foreground foliage passes faster than the collision plane. It is
 // confined below the player's feet and omitted over gaps so it never fakes a landing.
 const offset=-(cam*1.12)%310;
 for(let x=offset-310;x<960;x+=310){
  const screenX=snap(x),left=cam+screenX;
  if(!world.platforms.some(p=>p.ground&&left>=p.x&&left+76<=p.x+p.w))continue;
  ctx.globalAlpha=.8;ctx.drawImage(images.get('forest7'),52,96,38,22,screenX,448,76,44);ctx.globalAlpha=1;
 }
}
export function drawLantern(ctx,x,y,lit,time,reduced){
 rect(ctx,x-4,y-62,6,62,'#19282a');rect(ctx,x-6,y-64,30,4,'#8b7552');rect(ctx,x+18,y-60,2,10,'#514334');
 rect(ctx,x+12,y-50,14,24,'#111a20');rect(ctx,x+10,y-52,18,4,'#9d8760');rect(ctx,x+10,y-28,18,4,'#8d7751');
 rect(ctx,x+16,y-46,6,14,lit?'#ffdfa0':'#5b7067');
 if(lit){
  ctx.globalAlpha=.1;rect(ctx,x+4,y-58,30,40,'#ffd88b');ctx.globalAlpha=1;
  rect(ctx,x+18,y-44+(reduced?0:Math.floor(time*5)%2)*2,2,8,'#fff5d1');
 }
}
export function drawLandmarks(ctx,images,world,time,reduced){
 const {theme}=world.clearing;
 if(theme==='cave'||theme==='chapel'){
  for(const [i,p] of world.platforms.entries())if(p.ground){
   drawProp(ctx,images,theme==='cave'?'blue-mushrooms':'candle-shrine',p.x+Math.min(p.w-70,170),p.y+2,i%2===1);
   if(p.w>500)drawProp(ctx,images,theme==='cave'?'moss-rock':'carved-rubble',p.x+p.w-140,p.y+6,i%2===0);
  }
  world.clearing.checkpoints.forEach((x,i)=>drawLantern(ctx,x,420,world.checkpointId>i,time,reduced));
  drawLantern(ctx,96,420,true,time,reduced);return;
 }
 // Each clearing has its own trail banners, lamps and vegetation accents.
 for(const p of world.platforms){
  if(!p.ground&&p.w>=140){
   const x=p.x+Math.floor(p.w/2)-8;
   rect(ctx,x,p.y+24,18,36,theme==='cave'?'#28555a':theme==='chapel'?'#593d63':theme==='house'?'#5f304d':'#6e3540');
   rect(ctx,x+2,p.y+24,14,2,'#b98062');rect(ctx,x+8,p.y+34,2,12,'#dab87b');rect(ctx,x+4,p.y+38,10,4,'#dab87b');
   rect(ctx,x,p.y+56,6,4,'#17252b');
  }
  if(p.ground){
   for(let x=p.x+68;x<p.x+p.w-28;x+=122){
    rect(ctx,x,p.y-10,2,10,'#b1a483');rect(ctx,x-4,p.y-12,10,4,theme==='house'?'#a75d8b':'#ac5547');
    rect(ctx,x-2,p.y-12,2,2,'#efc482');
   }
   if(theme==='house'){
    for(let x=p.x+100;x<p.x+p.w-40;x+=180){
     rect(ctx,x,p.y+14,4,34,'#3b2941');rect(ctx,x-8,p.y+24,12,4,'#5c3b52');rect(ctx,x+4,p.y+36,10,4,'#5c3b52');
    }
   }
  }
 }
 world.clearing.checkpoints.forEach((x,i)=>drawLantern(ctx,x,420,world.checkpointId>i,time,reduced));
 // One lamp by the starting trail, welcoming rather than collectible.
 drawLantern(ctx,96,420,true,time,reduced);
}
export function drawTrailGate(ctx,images,world,time,reduced){
 const {x,y}=world.clearing.exit,ready=world.collected===3;
 rect(ctx,x-38,y-102,12,102,'#233737');rect(ctx,x+26,y-102,12,102,'#233737');
 rect(ctx,x-42,y-106,84,10,'#697154');rect(ctx,x-38,y-106,76,2,'#b6ab76');
 for(let i=0;i<3;i++){rect(ctx,x-20+i*16,y-100,8,8,'#122124');rect(ctx,x-18+i*16,y-98,4,4,i<world.collected?'#ffe6a6':'#485c55');}
 rect(ctx,x-30,y-90,60,90,ready?'#e8c77b12':'#081e282b');
 drawLantern(ctx,x-18,y-26,ready,time,reduced);
 ctx.font='12px Silkscreen, monospace';ctx.fillStyle=ready?'#ffdda3':'#a7ac8d';ctx.textAlign='center';ctx.fillText('WAY ON',x,y+16);ctx.textAlign='left';
}
