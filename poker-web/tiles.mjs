// Deterministic edge constraints applied to runtime pixel surfaces, never to source art.
// Generated textures are not assumed to be seamless merely because of their prompt.
export const TERRAIN_TILE_SIZE=96;
const mix=(a,b,t)=>Math.round(a+(b-a)*t);
export function periodicPixels(input,width,height,axes='xy',band=8,profile='mean'){
 const out=new Uint8ClampedArray(input);
 function join(horizontal){
  const length=horizontal?width:height,rows=horizontal?height:width,n=Math.min(band,Math.floor(length/2));
  const at=(x,y)=>horizontal?(y*width+x)*4:(x*width+y)*4;
  for(let y=0;y<rows;y++)for(let c=0;c<4;c++){
   const target=profile==='interior'?out[at(Math.floor(length/2),y)+c]:mix(out[at(0,y)+c],out[at(length-1,y)+c],.5);
   for(let x=0;x<n;x++){
    const strength=(1-x/n)**2;
    for(const p of [at(x,y)+c,at(length-1-x,y)+c])out[p]=mix(out[p],target,strength);
   }
  }
 }
 if(axes.includes('x'))join(true);if(axes.includes('y'))join(false);
 return out;
}
// Variants share a two-pixel frame, so ANY pair connects both horizontally and
// vertically, including all four-way corners. Only the interiors vary.
export function compatibleTile(input,canonical,width,height,band=5){
 const out=new Uint8ClampedArray(input);
 for(let y=0;y<height;y++)for(let x=0;x<width;x++){
  const edge=Math.min(x,y,width-1-x,height-1-y),t=edge<2?1:Math.max(0,1-(edge-1)/band);
  for(let c=0;c<4;c++){const p=(y*width+x)*4+c;out[p]=mix(out[p],canonical[p],t);}
 }
 return out;
}
export const tileVariant=(column,row)=>((column*13+row*7+(column^row)*3)%9+9)%9;
