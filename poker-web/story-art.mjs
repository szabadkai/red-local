// Story actors share the game's native two-world-unit pixel pitch.
// Atlas characters keep their original proportions. Large creatures are drawn
// in source-pixel coordinates so their silhouettes stay crisp at every scale.
export const STORY_IMAGES = {
  'story-mother': './assets/cast/mother_sheet.png',
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

function drawHart(c,time,state) {
  const moving=['charge','lunge','chase','approach','strike'].includes(state),stride=moving?Math.round(Math.sin(time*14)*3):0;
  // Hind legs and elongated body establish a deer, not a humanoid boss.
  line(c,-14,-18,-17+stride,-2,C.ink,4);line(c,-6,-18,-5-stride,-2,C.bark,4);
  line(c,13,-22,10+stride,-2,C.ink,4);line(c,6,-20,7-stride,-2,C.wood,3);
  poly(c,[[-21,-26],[-15,-33],[6,-33],[14,-28],[11,-15],[-13,-16]],C.ink);
  poly(c,[[-19,-26],[-13,-31],[6,-31],[11,-27],[8,-18],[-13,-19]],C.bark);
  line(c,-12,-29,4,-29,C.leaf,3);line(c,-16,-22,-4,-21,C.moss,2);
  poly(c,[[5,-27],[10,-39],[16,-41],[19,-33],[13,-20]],C.wood);
  poly(c,[[10,-40],[15,-44],[23,-40],[24,-36],[17,-34],[10,-36]],C.ink);
  poly(c,[[12,-40],[17,-41],[22,-38],[22,-36],[15,-36]],C.pale);
  rect(c,18,-40,2,2,C.eye);rect(c,23,-38,3,2,C.ink);
  line(c,11,-41,4,-51,C.bone,2);line(c,5,-49,-1,-49,C.bone,2);line(c,8,-44,1,-44,C.bone,2);
  line(c,15,-43,19,-54,C.bone,2);line(c,18,-49,25,-51,C.bone,2);line(c,19,-53,24,-55,C.bone);
  line(c,-20,-27,-24,-31,C.pale,2);thorns(c,-8,-21,1,18);thorns(c,3,-19,-1,15);
  chain(c,5,-46,11,-40);rect(c,5,-46,5,4,C.slate);rect(c,6,-45,3,2,C.silver);
}
function drawWolf(c,time,state) {
  const attacking=['bite','lunge','sweep','charge','attack','strike'].includes(state),move=attacking?Math.round(Math.sin(time*13)*2):0;
  const breath=Math.floor(time*2)%2;
  poly(c,[[-12,-29],[-22,-20],[-26,-12],[-19,-15],[-10,-18]],C.ink);
  poly(c,[[-12,-31],[1,-38],[12,-34],[16,-18],[7,-11],[-10,-16],[-17,-25]],C.ink);
  poly(c,[[-10,-30],[2,-36],[10,-32],[12,-19],[5,-15],[-8,-18]],C.slate);
  poly(c,[[-9,-31],[-3,-35],[0,-24],[-8,-20]],C.silver);
  line(c,-9,-17,-14+move,-2,C.ink,5);line(c,4,-14,8-move,-2,C.ink,5);
  rect(c,-16+move,-2,8,2,C.bone);rect(c,7-move,-2,8,2,C.bone);
  // Ears, snout and pale ruff remain visible in the black woodland silhouette.
  poly(c,[[0,-36],[0,-49],[5,-46],[12,-51],[14,-44],[22,-40],[20,-34],[8,-32]],C.ink);
  poly(c,[[3,-43],[7,-46],[12,-44],[13,-41],[21,-39],[19,-36],[10,-35],[3,-37]],C.slate);
  rect(c,10,-43,3,2,C.eye);rect(c,20,-40,4,3,C.ink);
  if(attacking){poly(c,[[12,-35],[24,-35],[18,-29],[11,-31]],C.ink);rect(c,14,-35,2,3,C.bone);rect(c,19,-35,2,2,C.bone);}
  else line(c,12,-35,20,-35,C.bone);
  poly(c,[[0,-37],[-4,-35],[1,-30],[5,-33],[8,-28],[10,-34]],C.pale);
  line(c,10,-29+breath,attacking?26:17,attacking?-23:-13,C.ink,5);
  for(let i=0;i<3;i++)line(c,attacking?26:17,attacking?-23+i*2:-13+i,attacking?31:20,attacking?-21+i*2:-9+i,C.bone);
  line(c,-13,-26,-16,-14,C.ink,4);line(c,-16,-14,-19,-9,C.bone);
}
function drawWidow(c,time,state) {
  const shift=Math.round(Math.sin(time*3)),lift=['windup','slam','attack','strike'].includes(state)?3:0;
  for(const side of [-1,1])for(let i=0;i<3;i++) {
    const hip=side*(7+i*3),knee=side*(20+i*5),foot=side*(27+i*3);
    line(c,hip,-26,knee,-33+i*7-lift,C.ink,3);line(c,knee,-33+i*7-lift,foot,-2+i%2*3,C.ink,3);
    line(c,hip,-27,knee,-34+i*7-lift,C.silver);line(c,knee,-33+i*7-lift,foot,-3+i%2*3,C.purple);
  }
  poly(c,[[-12,-36],[-7,-44],[5,-44],[12,-34],[18,-10],[8,-5],[0,-10],[-8,-4],[-18,-11]],C.ink);
  poly(c,[[-9,-35],[-5,-42],[4,-42],[9,-33],[14,-12],[6,-9],[0,-14],[-8,-8],[-14,-12]],C.purple);
  poly(c,[[-5,-40],[3,-40],[6,-33],[10,-13],[3,-17],[-3,-14],[-9,-12]],C.silk);
  line(c,-6,-35,-9,-16,C.cream);line(c,5,-34,9,-17,C.silver);
  rect(c,-4,-37+shift,8,6,C.ink);rect(c,-3,-36+shift,2,1,C.eye);rect(c,2,-36+shift,2,1,C.eye);
  rect(c,-2,-34+shift,4,1,C.slate);chain(c,-6,-24,8,-22);
  poly(c,[[-2,-23],[2,-23],[3,-18],[5,-16],[-5,-16],[-3,-18]],C.gold);rect(c,-5,-16,11,2,C.wood);rect(c,-1,-14,3,2,C.pale);
}
function drawTollkeeper(c,images,time,state) {
  const swing=['slam','attack','windup','strike'].includes(state);
  rect(c,-9,-13,6,13,C.ink);rect(c,4,-13,6,13,C.ink);rect(c,-11,-3,9,3,C.silver);rect(c,4,-3,9,3,C.silver);
  poly(c,[[-11,-37],[10,-37],[15,-29],[11,-11],[-11,-11],[-16,-28]],C.ink);
  rect(c,-11,-32,23,19,C.slate);rect(c,-9,-31,19,3,C.silver);rect(c,-8,-21,16,7,C.wood);
  atlas(c,images,128+Math.floor(time*3)%4*16,70,16,26,-8,-49);
  rect(c,-15,-31,6,11,C.slate);rect(c,12,-31,6,11,C.slate);rect(c,-16,-32,7,3,C.silver);
  chain(c,-11,-27,12,-15);chain(c,11,-29,-10,-16);
  rect(c,-4,-23,9,10,C.gold);rect(c,-2,-26,5,4,C.slate);rect(c,0,-20,2,4,C.ink);
  const hx=swing?24:20,hy=swing?-46:-12;chain(c,15,-27,hx,hy);
  line(c,hx,hy,hx+5,hy+3,C.silver,2);line(c,hx+5,hy+3,hx+2,hy+8,C.silver,2);
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
  if(id==='mother') {
    const img=images.get('story-mother');
    if(img)c.drawImage(img,f*32,move?32:0,32,32,-16,-32,32,32);
    return;
  }
  if(id==='stranger') {
    const img=images.get('story-traveler');if(img)c.drawImage(img,(f+(move?4:0))*16,0,16,32,-8,-32,16,32);
    // Fine walking stick and a white flower connect this traveler to the garden.
    line(c,10,-17,12,-1,C.wood);rect(c,11,-21,1,6,C.leaf);rect(c,9,-23,5,3,C.cream);
    return;
  }
  const rows={grandma:160,pip:224,rowan:32,wren:128};
  atlas(c,images,x,rows[id]??0,16,32,-8,-32);
  if(id==='grandma') {
    // Silver hair, glasses and a shawl distinguish her from the blue mage base.
    rect(c,-5,-20,9,3,C.silver);rect(c,-6,-18,3,4,C.pale);rect(c,3,-18,3,4,C.pale);
    rect(c,-3,-16,3,2,C.ink);rect(c,1,-16,3,2,C.ink);rect(c,0,-16,1,1,C.gold);
    poly(c,[[-5,-12],[0,-9],[5,-12],[7,-4],[1,-2],[-7,-4]],C.purple);line(c,7,-11,8,-1,C.wood,2);
  } else if(id==='rowan') {
    poly(c,[[-7,-16],[0,-18],[6,-16],[3,-13],[-7,-13]],C.leaf);rect(c,-6,-8,12,3,C.wood);
    const swing=['windup','attack','swing','strike'].includes(state);
    line(c,9,-1,swing?17:12,swing?-30:-26,C.wood,2);
    poly(c,swing?[[15,-31],[23,-28],[22,-22],[15,-24]]:[[10,-27],[18,-24],[17,-18],[10,-20]],C.silver);
    line(c,swing?23:18,swing?-28:-24,swing?22:17,swing?-22:-18,C.cream,2);
  } else if(id==='wren') {
    rect(c,-5,-11,11,2,C.pale);rect(c,0,-11,2,8,C.pale);rect(c,-2,-8,6,1,C.gold);
    line(c,9,-15,9,-1,C.wood);rect(c,7,-18,5,4,C.gold);
  } else if(id==='pip') {
    const hatBob=move?[0,-2,-1,2][f]:[0,0,3,1][f];
    rect(c,-5,-21+hatBob,10,3,C.gold);rect(c,-7,-19+hatBob,15,2,C.wood);line(c,9,-25,10,-1,C.wood,2);
    rect(c,8,-3,5,4,C.gold);
  }
}

export function drawStoryActor(ctx,images,id,x,y,time,{facing=1,state='idle',flash=0,scale=2}={}) {
  if(!ctx||!images||!Number.isFinite(x)||!Number.isFinite(y)||!Number.isFinite(scale)||scale<=0)return;
  ctx.save();ctx.imageSmoothingEnabled=false;ctx.translate(Math.round(x/2)*2,Math.round(y/2)*2);
  ctx.scale((facing<0?-1:1)*scale,scale);if(flash>0)ctx.globalAlpha=.58;
  if(id==='hart')drawHart(ctx,time,state);
  else if(id==='wolf')drawWolf(ctx,time,state);
  else if(id==='widow')drawWidow(ctx,time,state);
  else if(id==='tollkeeper')drawTollkeeper(ctx,images,time,state);
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
    red:[0,-11],mother:[0,-13],grandma:[0,-13],pip:[0,-11],rowan:[0,-11],
    wren:[0,-12],stranger:[0,-9],hart:[8,-30],wolf:[7,-30],widow:[0,-27],tollkeeper:[0,-27]
  }[id]??[0,-11];
  drawStoryActor(ctx,images,id,width/2-focus[0]*scale,height/2-focus[1]*scale,time,{scale});
}

function cottage(c,time,bed=true) {
  rect(c,4,42,472,161,'#272c30');
  for(let x=4;x<480;x+=32){rect(c,x,42,2,161,'#3c3936');rect(c,x,201,30,2,'#554637');}
  rect(c,4,42,472,8,C.bark);rect(c,16,41,9,169,C.wood);rect(c,456,41,9,169,C.wood);
  hearth(c,93,210,true,time);table(c,189,210);
  rect(c,350,86,53,57,C.ink);rect(c,354,90,45,49,C.blue);rect(c,375,90,3,49,C.wood);rect(c,354,113,45,3,C.wood);
  poly(c,[[354,90],[366,90],[362,138],[354,138]],C.purple);poly(c,[[386,90],[399,90],[399,138],[391,138]],C.purple);
  if(bed){rect(c,306,176,107,27,C.bark);rect(c,304,167,6,43,C.wood);rect(c,410,181,6,29,C.wood);rect(c,311,177,98,13,C.pale);rect(c,331,176,77,20,C.red);for(let x=335;x<408;x+=12)rect(c,x,180,5,5,C.gold);rect(c,313,176,17,8,C.cream);}
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
    rect(ctx,306,58,153,152,'#373831');poly(ctx,[[293,58],[384,23],[472,58]],C.bark);
    rect(ctx,354,125,42,85,C.ink);rect(ctx,360,130,30,80,C.wood);rect(ctx,365,148,20,21,C.gold);
    rect(ctx,318,92,24,31,C.ink);rect(ctx,322,96,16,23,C.gold);rect(ctx,409,92,24,31,C.ink);rect(ctx,413,96,16,23,C.gold);
    for(let i=0;i<7;i++){thorns(ctx,i*11+8,210,1,25+i%3*10);thorns(ctx,478-i*7,210,-1,21+i%3*14);}
    for(let i=0;i<10;i++){const x=83+i*27;line(ctx,x,210,x,202,C.leaf);rect(ctx,x-2,199,5,4,C.cream);}
  } else if(location==='arena') {
    if(stage===0) {
      for(const x of [9,23,41,449,463,477])thorns(ctx,x,210,x<200?1:-1,42+(x%7)*3);
      poly(ctx,[[0,176],[28,170],[47,191],[67,210],[0,210]],C.bark);poly(ctx,[[480,175],[453,172],[436,190],[419,210],[480,210]],C.bark);
      lantern(ctx,76,175,t);lantern(ctx,403,175,t);
    } else if(stage===1) {
      // Wheel lives behind the arena; its spokes hint at the sweep timing.
      ellipse(ctx,385,128,67,67,C.bark);ellipse(ctx,385,128,61,61,C.ink);ellipse(ctx,385,128,55,55,'#364541');
      for(let i=0;i<8;i++){const a=t*.16+i*Math.PI/4;line(ctx,385,128,385+Math.cos(a)*62,128+Math.sin(a)*62,C.wood,4);}
      ellipse(ctx,385,128,8,8,C.slate);rect(ctx,376,194,18,16,C.bark);
      rect(ctx,8,120,72,90,C.bark);rect(ctx,14,130,60,80,C.wood);rect(ctx,39,159,22,51,C.ink);
      chain(ctx,14,88,467,88);lantern(ctx,80,153,t);
    } else if(stage===2) {
      poly(ctx,[[17,210],[52,144],[91,210]],C.bark);poly(ctx,[[26,210],[52,156],[77,210]],C.wood);poly(ctx,[[40,210],[52,174],[63,210]],C.ink);
      rect(ctx,381,199,56,11,C.bark);rect(ctx,386,196,47,4,C.moss);lantern(ctx,411,168,t);
      for(let i=0;i<4;i++){rect(ctx,11+i*5,105+i*8,2,18,C.leaf);rect(ctx,461-i*7,87+i*9,2,23,C.moss);}
      rect(ctx,117,203,20,7,C.wood);poly(ctx,[[118,202],[125,184-Math.floor(t*4)%3],[135,202]],C.gold);rect(ctx,126,196,3,6,C.cream);
    } else if(stage===3) {
      for(const x of [31,105,366,440]){rect(ctx,x,44,12,166,C.slate);rect(ctx,x-4,43,20,9,C.silver);rect(ctx,x-4,201,20,9,C.slate);}
      poly(ctx,[[157,111],[157,72],[240,32],[323,72],[323,111],[312,105],[312,80],[240,47],[168,80],[168,105]],C.slate);
      bell(ctx,240,100,t,!world.boss||world.boss.hp<=0);
      line(ctx,240,108,240,158,C.silk);ellipse(ctx,240,169,10,16,C.slate);
      for(let y=157;y<181;y+=4)line(ctx,231,y,249,y+4,C.silk);
      for(let i=0;i<5;i++){line(ctx,12+i*4,45,216,151,C.silk);line(ctx,469-i*4,45,265,153,C.silk);}
      for(const x of [65,402]){rect(ctx,x,181,18,5,C.wood);rect(ctx,x+2,186,3,24,C.bark);rect(ctx,x+13,186,3,24,C.bark);}
    } else cottage(ctx,t);
  } else {
    // Small story landmarks near each entrance avoid obscuring the existing routes.
    if(stage===0){rect(ctx,8,142,7,68,C.wood);rect(ctx,108,142,7,68,C.wood);rect(ctx,8,141,107,5,C.bark);lantern(ctx,20,158,t);table(ctx,43,210);}
    if(stage===1){rect(ctx,58,175,4,35,C.wood);rect(ctx,39,172,43,12,C.bark);rect(ctx,43,176,33,2,C.gold);rect(ctx,48,181,22,1,C.pale);}
    if(stage===2){poly(ctx,[[14,210],[44,171],[75,210]],C.bark);poly(ctx,[[33,210],[44,184],[57,210]],C.ink);lantern(ctx,82,184,t);}
    if(stage===3){bell(ctx,46,147,t);for(const x of [25,66]){rect(ctx,x,144,5,66,C.slate);rect(ctx,x-2,140,9,5,C.silver);}}
    if(stage===4){thorns(ctx,18,210,1,40);thorns(ctx,86,210,-1,34);for(const x of [34,50,67]){line(ctx,x,210,x,199,C.leaf);rect(ctx,x-2,197,5,3,C.cream);}}
  }
  ctx.restore();
}
