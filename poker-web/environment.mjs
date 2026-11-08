import {snap} from './art.mjs';
import {tileVariant,TERRAIN_TILE_SIZE} from './tiles.mjs';

// Source rectangles reference the original project sheets; source pixels always render at 2x.
function painter(ctx,images){
 const rect=(x,y,w,h,color)=>{ctx.fillStyle=color;ctx.fillRect(snap(x),snap(y),snap(w),snap(h))};
 const sprite=(sheet,sx,sy,w,h,x,y)=>ctx.drawImage(images.get(sheet),sx,sy,w,h,snap(x),snap(y),w*2,h*2);
 return {rect,sprite};
}

export function drawTerrain(ctx,images,platforms,time,reduced,theme='wood'){
 const tileSize=TERRAIN_TILE_SIZE,tileWorld=tileSize*2;
 const {rect,sprite}=painter(ctx,images),ground=platforms.filter(p=>p.ground).sort((a,b)=>a.x-b.x);
 for(let i=1;i<ground.length;i++){
  const left=ground[i-1].x+ground[i-1].w,right=ground[i].x,y=ground[i].y;
  if(right<=left)continue;
  ctx.save();ctx.beginPath();ctx.rect(left,y,right-left,200);ctx.clip();
  rect(left,y,right-left,200,'#09121d');
  if(theme==='cave'||theme==='chapel'){
   const tiles=images.get('tiles-'+theme);ctx.globalAlpha=.45;
   for(let row=0;row<4;row++){
    const variant=tileVariant(i,row);ctx.drawImage(tiles,variant*tileSize,0,tileSize,tileSize,snap(left-tileWorld+18-row*4),y+row*tileWorld,tileWorld,tileWorld);
    ctx.drawImage(tiles,variant*tileSize,0,tileSize,tileSize,snap(right-18+row*4),y+row*tileWorld,tileWorld,tileWorld);
   }
   ctx.globalAlpha=1;ctx.restore();continue;
  }
  // Recessed rock faces recede toward the dark center, behind the actual landing edges.
  ctx.globalAlpha=.35;
  for(let row=0;row<6;row++){
   sprite('terrain',48,32,16,16,left+10-row*4,y+row*32);
   sprite('terrain',16,32,16,16,right-42+row*4,y+row*32);
  }
  ctx.globalAlpha=1;
  for(let j=0;j<3;j++){
   const drift=reduced?0:snap((time*7+j*18)%28);
   rect(left+28+j*18+drift,y+30+j*24,20,2,'#1b2d36');
  }
  ctx.restore();
 }
 for(const p of platforms){
  if(theme==='cave'||theme==='chapel'){
   const cave=theme==='cave',depth=p.ground?160:24,tiles=images.get('tiles-'+theme);
   ctx.save();ctx.beginPath();ctx.rect(p.x,p.y,p.w,depth);ctx.clip();
   for(let row=0;row*tileWorld<depth;row++)for(let col=0;col*tileWorld<p.w;col++){
    const variant=tileVariant(col+Math.floor(p.x/tileWorld),row);
    ctx.drawImage(tiles,variant*tileSize,0,tileSize,tileSize,p.x+col*tileWorld,p.y+row*tileWorld,tileWorld,tileWorld);
   }
   rect(p.x,p.y,p.w,2,cave?'#96976c':'#b4c6ac');
   rect(p.x,p.y+2,p.w,2,cave?'#687356':'#687b78');
   // Small broken moss clusters vary along a continuous readable landing lip.
   if(cave)for(let x=p.x+4;x<p.x+p.w;x+=14){
    const n=tileVariant(Math.floor(x/14),p.id);rect(x,p.y+4,6+(n%3)*2,2+(n%2)*2,'#495241');
   }
   rect(p.x,p.y+depth-2,p.w,2,'#101820');
   rect(p.x,p.y+4,2,depth-6,'#477077');rect(p.x+p.w-2,p.y+4,2,depth-6,'#101820');
   ctx.restore();
   continue;
  }
  // Clip the final tile instead of stretching it, preserving the exact collision span.
  ctx.save();ctx.beginPath();ctx.rect(p.x,p.y,p.w,p.ground?160:24);ctx.clip();
  const depth=p.ground?160:24;
  rect(p.x,p.y,p.w,depth,'#111d29');
  for(let y=p.y;y<p.y+depth;y+=32){
   const sy=y===p.y?16:32;
   for(let x=p.x+32;x<p.x+p.w-32;x+=32)sprite('terrain',32,sy,16,16,x,y);
   sprite('terrain',16,sy,16,16,p.x,y);sprite('terrain',48,sy,16,16,p.x+p.w-32,y);
  }
  if(theme!=='wood'&&images.has('paint-stone')){
   for(let y=p.y+10;y<p.y+depth;y+=192)for(let x=p.x;x<p.x+p.w;x+=192)ctx.drawImage(images.get('paint-stone'),x,y,192,192);
   rect(p.x,p.y+10,p.w,depth,theme==='house'?'#21162770':'#142e3650');
  }
  ctx.restore();
  // Keep low plants clear of takeoff/landing edges. Lantern Wood's painted
  // undergrowth supplies the larger silhouettes without repeated oval bushes.
  if(p.ground){
   for(let x=p.x+76;x<p.x+p.w-50;x+=142){
    sprite('terrain',368,32,16,16,x,p.y-32);
   }
   if(p.w>300){
    sprite('terrain',416,32,32,16,p.x+140,p.y-28);
    if(theme!=='wood')sprite('forest7',52,96,38,22,p.x+p.w-168,p.y-44);
   }
  }else{
   sprite('terrain',368,32,16,16,p.x+18,p.y-32);
   if(p.w>140)sprite('terrain',384,32,16,16,p.x+p.w-60,p.y-32);
  }
 }
 // Broken timber and hanging rope mark the two sides of each missing crossing.
 for(let i=1;i<ground.length;i++){
  const left=ground[i-1].x+ground[i-1].w,right=ground[i].x,y=ground[i].y;
  if(right<=left)continue;
  if(theme!=='cave'&&theme!=='chapel'){
   sprite('terrain',288,24,8,20,left-12,y+4);
   sprite('terrain',344,24,8,20,right-4,y+6);
  }
 }
}

export function drawHome(ctx,images,collected,time,reduced){
 const {rect,sprite}=painter(ctx,images),ready=collected===3;
 // A small sanctuary assembled from the original gothic roof/walls, door and timber assets.
 // Its doorway remains centered on the existing win trigger (2310, 300).
 sprite('terrain',288,16,64,8,2246,300);
 sprite('terrain',288,24,8,40,2246,316);
 sprite('terrain',344,24,8,40,2358,316);
 sprite('gothic',236,24,52,58,2258,184);
 rect(2294,254,32,46,ready?'#ffd083':'#1b2632');
 sprite('gothic',68,144,20,32,2290,236);
 if(ready){
  rect(2300,266,20,34,'#ffe4a6');rect(2298,296,24,4,'#fff1c1');
  ctx.globalAlpha=.12;rect(2288,276,44,24,'#ffe4a6');ctx.globalAlpha=1;
 }
 // Three inset ember sockets communicate why the entrance is still closed.
 for(let i=0;i<3;i++){
  rect(2294+i*12,230,8,8,'#101722');rect(2296+i*12,232,4,4,i<collected?'#ffe7a0':'#59645d');
 }
 // A planted timber sign and hanging lantern make the destination legible at a glance.
 sprite('terrain',288,24,8,28,2212,244);
 rect(2198,240,58,26,'#17202a');rect(2200,242,54,22,'#78523e');
 rect(2202,244,50,2,'#b68a58');rect(2202,260,50,2,'#49352e');
 ctx.fillStyle='#fff0b8';ctx.font='14px Silkscreen, monospace';ctx.fillText('HOME',2206,258);
 const frame=reduced?0:Math.floor(time*6)%3;
 rect(2346,242,4,44,'#342b2c');rect(2342,240,14,4,'#a58b5b');
 rect(2340,248,16,24,'#111a25');rect(2344,252,8,14,ready?'#ffeab2':'#e4ad60');
 rect(2346,254+frame*2,4,8,ready?'#fff9d8':'#ffdb8d');
 sprite('terrain',416,48,32,16,2328,280);
}
