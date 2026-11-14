import {BOSS_STATS} from './bosses.mjs';
import {drawArena as arenaArt} from './arena-art.mjs';
import {drawProp} from './concept-props.mjs';
const drawArena=(c,images,stage,t,reduced,world)=>arenaArt(c,stage,t,reduced,world,images);
// Story actors share the game's native two-world-unit pixel pitch.
// Atlas characters keep their original proportions. Large creatures are drawn
// in source-pixel coordinates so their silhouettes stay crisp at every scale.
export const STORY_IMAGES = {
  'story-mother': './assets/cast/mother_sheet.png',
  'story-grandma': './assets/cast/grandmother_sheet.png',
  'story-rowan': './assets/cast/woodcutter_sheet.png',
  'story-disguise': './assets/cast/wolf_in_disguise_sheet.png',
  'boss-hart': './assets/bosses/briar_hart_sheet.png',
  'boss-wolf': './assets/cast/big_bad_wolf_sheet.png',
  'boss-widow': './assets/bosses/bell_widow_sheet.png',
  'boss-tollkeeper': './assets/bosses/tollkeeper_sheet.png',
  'story-traveler': './assets/story/traveler.png',
  'story-pumpkin': './assets/story/pumpkin.png'
};

const C = {
  ink:'#131c22', shadow:'#20282d', slate:'#34434b', silver:'#889b98', bone:'#d3ceae',
  cream:'#e7d9af', wood:'#624b39', bark:'#3e3b30', leaf:'#526b44', moss:'#859360',
  red:'#9e4051', ruby:'#d77869', gold:'#bc9560', pale:'#c8baa0', blue:'#61758a',
  purple:'#685169', silk:'#aaa9b2', eye:'#edbe70', ember:'#e9ba76'
};
const rect = (c,x,y,w,h,color) => { c.fillStyle=color;c.fillRect(Math.round(x),Math.round(y),w,h); };
function line(c,x0,y0,x1,y1,color,width=1) {
  x0=Math.round(x0);y0=Math.round(y0);x1=Math.round(x1);y1=Math.round(y1);
  const dx=Math.abs(x1-x0),sx=x0<x1?1:-1,dy=-Math.abs(y1-y0),sy=y0<y1?1:-1;
  let error=dx+dy;
  for(let step=0;step<2048;step++) {
    rect(c,x0,y0,width,width,color);if(x0===x1&&y0===y1)break;
    const e=2*error;if(e>=dy){error+=dy;x0+=sx;}if(e<=dx){error+=dx;y0+=sy;}
  }
}
function ellipse(c,x,y,rx,ry,color) {
  for(let row=-ry;row<=ry;row++) {
    const half=Math.floor(rx*Math.sqrt(Math.max(0,1-row*row/(ry*ry))));
    rect(c,x-half,y+row,half*2+1,1,color);
  }
}
// Integer scanline fill avoids antialiased outlines from canvas paths.
function poly(c,points,color) {
  const ys=points.map(p=>p[1]);
  for(let y=Math.floor(Math.min(...ys));y<=Math.ceil(Math.max(...ys));y++) {
    const hits=[];
    for(let i=0;i<points.length;i++) {
      const a=points[i],b=points[(i+1)%points.length];
      if((a[1]<=y&&b[1]>y)||(b[1]<=y&&a[1]>y))hits.push(a[0]+(y-a[1])*(b[0]-a[0])/(b[1]-a[1]));
    }
    hits.sort((a,b)=>a-b);
    for(let i=0;i+1<hits.length;i+=2)rect(c,Math.ceil(hits[i]),y,Math.floor(hits[i+1])-Math.ceil(hits[i])+1,1,color);
  }
}
function atlas(c,images,x,y,w,h,dx,dy) {
  const img=images.get('dungeon');if(img)c.drawImage(img,x,y,w,h,dx,dy,w,h);
}
function chain(c,x0,y0,x1,y1) {
  const length=Math.hypot(x1-x0,y1-y0),steps=Math.max(1,Math.ceil(length/4));
  for(let i=0;i<=steps;i++) {
    const x=Math.round(x0+(x1-x0)*i/steps),y=Math.round(y0+(y1-y0)*i/steps);
    rect(c,x-1,y-1,3,3,C.slate);rect(c,x,y,1,1,C.silver);
  }
}
// Guy lines converge on the cocoon; sagging cross threads tie neighbouring strands.
function web(c,anchors,[hx,hy]) {
  for(const [x,y] of anchors)line(c,x,y,hx,hy,C.silk);
  for(const t of [.3,.55,.78])for(let i=0;i+1<anchors.length;i++) {
    const [ax,ay]=anchors[i],[bx,by]=anchors[i+1];
    const x0=ax+(hx-ax)*t,y0=ay+(hy-ay)*t,x1=bx+(hx-bx)*t,y1=by+(hy-by)*t,mx=(x0+x1)/2,my=(y0+y1)/2+3;
    line(c,x0,y0,mx,my,C.silk);line(c,mx,my,x1,y1,C.silk);
  }
}
function lantern(c,x,y,time,lit=true) {
  line(c,x,y-13,x,y-5,C.wood,2);rect(c,x-4,y-7,10,11,C.ink);
  rect(c,x-2,y-5,6,6,lit?C.gold:C.slate);if(lit)rect(c,x,y-4,2,4,Math.floor(time*3)%2?C.cream:C.ember);
  rect(c,x-5,y-8,12,2,C.slate);rect(c,x-4,y+4,10,2,C.slate);
}
function thorns(c,x,y,dir=1,height=24) {
  line(c,x,y,x+dir*4,y-height,C.bark,3);
  for(let i=4;i<height;i+=6) {
    line(c,x+dir*2,y-i,x+dir*10,y-i-6,C.leaf,2);
    line(c,x+dir*2,y-i-3,x-dir*4,y-i-8,C.moss);
  }
}
function hearth(c,x,y,lit,time) {
  rect(c,x-22,y-52,44,52,C.ink);rect(c,x-20,y-50,40,9,C.slate);
  rect(c,x-23,y-43,46,5,C.silver);rect(c,x-20,y-38,8,38,C.slate);rect(c,x+12,y-38,8,38,C.slate);
  for(let i=0;i<4;i++){rect(c,x-20,y-35+i*9,8,1,C.ink);rect(c,x+12,y-35+i*9,8,1,C.ink);}
  rect(c,x-24,y-3,48,4,C.slate);rect(c,x-10,y-7,22,3,C.wood);
  if(lit){poly(c,[[x-8,y-7],[x-5,y-16],[x,y-10],[x+3,y-23-Math.floor(time*4)%3],[x+9,y-7]],C.gold);poly(c,[[x-3,y-7],[x,y-15],[x+5,y-7]],C.cream);}
}
function table(c,x,y) {
  rect(c,x-22,y-22,44,5,C.wood);rect(c,x-20,y-18,4,18,C.bark);rect(c,x+16,y-18,4,18,C.bark);
  rect(c,x-18,y-23,36,2,C.gold);rect(c,x-6,y-29,14,6,C.gold);rect(c,x-4,y-31,10,2,C.cream);
  line(c,x-4,y-26,x+4,y-26,C.wood);
}
function bell(c,x,y,time,ringing=false) {
  rect(c,x-3,y-30,6,20,C.bark);line(c,x,y-30,x,y-53,C.wood,2);
  const sway=ringing?Math.round(Math.sin(time*3)*2):0;
  c.save();c.translate(sway,0);
  poly(c,[[x-5,y-15],[x+5,y-15],[x+8,y-3],[x+12,y+3],[x-12,y+3],[x-8,y-3]],C.ink);
  poly(c,[[x-4,y-14],[x+4,y-14],[x+6,y-2],[x+10,y+1],[x-10,y+1],[x-6,y-2]],C.gold);
  line(c,x-3,y-12,x-5,y-1,C.cream,2);rect(c,x-12,y+2,25,3,C.wood);rect(c,x-1,y+5,3,3,C.pale);
  c.restore();
}

function drawKnot(c,time) {
  ellipse(c,0,-12,12,12,C.ink);ellipse(c,0,-12,9,9,C.purple);
  for(let i=-8;i<=8;i+=4){line(c,i,-21,-i,-3,C.bark,2);line(c,-i,-21,i,-3,C.moss);}
  rect(c,-3,-14,6,5,Math.floor(time*2)%2?C.ruby:C.gold);
  thorns(c,-9,-1,-1,17);thorns(c,8,-1,1,16);
}
function drawHuman(c,images,id,time,state) {
  const move=['walk','run','chase','lunge','approach'].includes(state),f=Math.floor(time*(move?7:3))%4;
  const x=128+(move?64:0)+f*16;
  // Roster characters: 32x32 cells, rows idle / run / attack.
  if(['mother','grandma','rowan','disguise'].includes(id)) {
    const img=images.get('story-'+id),swing=id==='rowan'&&['windup','attack','swing','strike'].includes(state);
    const row=swing?2:move?1:0,frame=swing?Math.floor(time*10)%6:f;
    if(img)c.drawImage(img,frame*32,row*32,32,32,-16,-32,32,32);
    return;
  }
  if(id==='stranger') {
    const img=images.get('story-traveler');if(img)c.drawImage(img,(f+(move?4:0))*16,0,16,32,-8,-32,16,32);
    // Fine walking stick and a white flower connect this traveler to the garden.
    line(c,10,-17,12,-1,C.wood);rect(c,11,-21,1,6,C.leaf);rect(c,9,-23,5,3,C.cream);
    return;
  }
  const rows={pip:224,wren:128};
  atlas(c,images,x,rows[id]??0,16,32,-8,-32);
  if(id==='wren') {
    rect(c,-5,-11,11,2,C.pale);rect(c,0,-11,2,8,C.pale);rect(c,-2,-8,6,1,C.gold);
    line(c,9,-15,9,-1,C.wood);rect(c,7,-18,5,4,C.gold);
  } else if(id==='pip') {
    const hatBob=move?[0,-2,-1,2][f]:[0,0,3,1][f];
    rect(c,-5,-21+hatBob,10,3,C.gold);rect(c,-7,-19+hatBob,15,2,C.wood);line(c,9,-25,10,-1,C.wood,2);
    rect(c,8,-3,5,4,C.gold);
  }
}

// Boss sheets: 48x48 cells, rows idle / run / attack(6) / special(8) / hit(4) / death(8).
// Each boss alternates a main pattern (attack row) with a phase-two pattern (special row).
const BOSS_SPECIAL={hart:'roots',tollkeeper:'slam',widow:'rings',wolf:'leap'};
// The Wolf is the roster's own big_bad_wolf (32x32 cells, same rows).
const BOSS_CELL={wolf:32};
const BOSS_DEATH_MS=[100,100,80,140,160,160,160];
function bossFrame(id,time,state,flash,b) {
  const size=BOSS_CELL[id]||48,cell=(row,i)=>[i*size,row*size];
  if(state==='dead') {
    // The death row at its authored timing (ms per frame), then the last frame holds.
    let t=(b?.deadTime??0)*1000,i=0;
    for(const ms of BOSS_DEATH_MS){if(t<ms)break;t-=ms;i++;}
    return cell(5,Math.min(7,i));
  }
  const hurt=b?.hurt??(flash>0?.3:0),t=.3-hurt;
  if(hurt>0&&!['windup','strike'].includes(state))return cell(4,t<.06?0:Math.min(3,1+Math.floor((t-.06)/.08)));
  if(hurt>0&&t<.06)return cell(4,0);
  const special=b?.pattern===BOSS_SPECIAL[id];
  if(state==='windup') {
    const total=Math.max(.01,BOSS_STATS[id].tell*(b?.garden?.85:1)),t=1-Math.max(0,b?.wind??0)/total;
    return special?cell(3,Math.min(3,Math.floor(t*4))):cell(2,Math.min(2,Math.floor(t*3)));
  }
  if(state==='strike') {
    const t=Math.min(1,(b?.elapsed??0)/Math.max(.01,b?.duration??.3));
    return special?cell(3,4+Math.min(3,Math.floor(t*4))):cell(2,3+Math.min(2,Math.floor(t*3)));
  }
  if(['approach','walk','run','chase','charge'].includes(state))return cell(1,Math.floor(time*8)%4);
  return cell(0,Math.floor(time*4)%4);
}

export function drawStoryActor(ctx,images,id,x,y,time,{facing=1,state='idle',flash=0,scale=2,boss=null}={}) {
  if(!ctx||!images||!Number.isFinite(x)||!Number.isFinite(y)||!Number.isFinite(scale)||scale<=0)return;
  ctx.save();ctx.imageSmoothingEnabled=false;ctx.translate(Math.round(x/2)*2,Math.round(y/2)*2);
  ctx.scale((facing<0?-1:1)*scale,scale);
  const sheet=BOSS_SPECIAL[id]&&images.get('boss-'+id);
  if(flash>0&&!sheet)ctx.globalAlpha=.58;
  if(sheet) {
    const [sx,sy]=bossFrame(id,time,state,flash,boss),size=BOSS_CELL[id]||48;
    ctx.drawImage(sheet,sx,sy,size,size,-size/2,-size,size,size);
  }
  else if(id==='knot')drawKnot(ctx,time);
  else if(id==='pumpkin') {
    const img=images.get('story-pumpkin');if(img)ctx.drawImage(img,Math.floor(time*3)%4*16,0,16,32,-8,-32,16,32);
  } else if(id==='red') {
    const img=images.get('light/idle_blink/'+(Math.floor(time*2)%8===0?1:0));
    if(img)ctx.drawImage(img,-8,-18);
  } else drawHuman(ctx,images,id,time,state);
  ctx.restore();
}

export function drawStoryPortrait(ctx,images,id,time) {
  if(!ctx||!images)return;
  const width=ctx.canvas.width,height=ctx.canvas.height;
  ctx.clearRect(0,0,width,height);ctx.imageSmoothingEnabled=false;
  const large=['hart','wolf','widow','tollkeeper'].includes(id);
  const scale=Math.max(1,Math.min(large?2:4,Math.floor(Math.min(width,height)/24)));
  // Focus the visible head and torso, not the transparent 32px atlas cell.
  // Tall weapons, legs and outer spider limbs may crop; faces remain centered.
  const focus={
    red:[0,-11],mother:[0,-13],grandma:[0,-12],disguise:[0,-11],pip:[0,-11],rowan:[0,-16],
    wren:[0,-12],stranger:[0,-9],hart:[6,-29],wolf:[6,-14],widow:[5,-25],tollkeeper:[1,-28]
  }[id]??[0,-11];
  drawStoryActor(ctx,images,id,width/2-focus[0]*scale,height/2-focus[1]*scale,time,{scale});
}

// Drawn again over an actor so whoever is in bed stays tucked in.
export function bedCover(c) {
  rect(c,362,178,66,10,C.red);rect(c,362,178,66,2,C.ruby);for(let x=366;x<426;x+=12)rect(c,x,182,4,3,C.gold);
}

export function drawStorySet(ctx,images,world,time,reduced=false) {
  if(!ctx||!world)return;
  const location=world.storyLocation??'trail',stage=world.stageIndex??0,t=reduced?0:time;
  ctx.save();ctx.imageSmoothingEnabled=false;ctx.scale(2,2);
  if(location==='inside') {
    rect(ctx,0,20,480,190,'#272332');
    for(let i=0;i<9;i++){const x=i*59;poly(ctx,[[x,20],[x+21,20],[x+31,143],[x+21,210],[x+8,210],[x+17,143]],i%2?'#38303d':'#423442');}
    rect(ctx,28,104,50,106,C.ink);rect(ctx,32,109,42,101,'#4a4651');rect(ctx,32,109,5,101,C.silver);
    hearth(ctx,406,210,false,t);table(ctx,247,210);bell(ctx,207,82,t,true);
    line(ctx,250,210,300,164,C.red,2);line(ctx,300,164,361,120,C.red,2);line(ctx,361,120,443,65,C.red,2);
    for(let i=0;i<13;i++){const x=(i*71)%470,y=38+(i*37)%130;rect(ctx,x,y,2,2,Math.floor(t+i)%3?C.pale:C.gold);}
  } else if(location==='home') {
    rect(ctx,0,24,480,186,'#6a7468');rect(ctx,0,140,480,70,'#394d3f');
    for(let x=16;x<480;x+=24){rect(ctx,x,164,4,46,C.wood);rect(ctx,x-2,161,8,5,C.gold);}
    rect(ctx,0,178,480,4,C.gold);rect(ctx,0,194,480,4,C.wood);
    rect(ctx,173,118,7,92,C.wood);rect(ctx,302,118,7,92,C.wood);rect(ctx,172,116,138,7,C.wood);
    poly(ctx,[[166,117],[239,89],[316,117]],C.bark);lantern(ctx,185,133,t);lantern(ctx,291,133,t);table(ctx,389,210);
  } else if(location==='garden') {
    rect(ctx,306,58,153,152,'#373831');for(let x=314;x<459;x+=10)rect(ctx,x,60,1,150,'#2b2c27');
    poly(ctx,[[293,58],[384,23],[472,58]],C.bark);for(let y=33;y<58;y+=6){const half=Math.round((y-23)*89/35);rect(ctx,384-half,y,half*2,1,C.ink);}
    line(ctx,294,57,384,24,C.wood);rect(ctx,293,58,180,3,C.ink);
    rect(ctx,354,125,42,85,C.ink);rect(ctx,360,130,30,80,C.wood);for(let x=367;x<390;x+=7)rect(ctx,x,130,1,80,C.bark);rect(ctx,365,148,20,21,C.gold);rect(ctx,374,148,2,21,C.ink);
    for(const x of [318,409]){rect(ctx,x,92,24,31,C.ink);rect(ctx,x+4,96,16,23,C.gold);rect(ctx,x+11,96,2,23,C.ink);rect(ctx,x+4,106,16,2,C.ink);rect(ctx,x+2,123,20,2,C.wood);}
    for(let i=0;i<7;i++){thorns(ctx,i*11+8,210,1,25+i%3*10);thorns(ctx,478-i*7,210,-1,21+i%3*14);}
    for(let i=0;i<10;i++){const x=83+i*27;line(ctx,x,210,x,202,C.leaf);rect(ctx,x-2,199,5,4,C.cream);}
  } else if(location==='arena') {
    drawArena(ctx,images,stage,t,reduced,world);
    if(stage===3){web(ctx,[[12,44],[50,44],[12,98]],[216,151]);web(ctx,[[468,44],[430,44],[468,98]],[265,153]);}
  } else {
    // Small story landmarks near each entrance avoid obscuring the existing routes.
    // Painted concept props mark each clearing's entrance (world units, so undo the 2x set scale).
    ctx.save();ctx.scale(.5,.5);
    if(stage===0){drawProp(ctx,images,'ivyarch',112,420,.5);drawProp(ctx,images,'fernrock',268,422,.3);}
    if(stage===2){drawProp(ctx,images,'rootcol',60,420,.42);drawProp(ctx,images,'shrooms',150,420,.28);}
    if(stage===3){drawProp(ctx,images,'shrine',80,420,.32);drawProp(ctx,images,'pillar',150,420,.42);}
    if(stage===4){drawProp(ctx,images,'ruins',90,422,.34);}
    ctx.restore();
  }
  ctx.restore();
}
