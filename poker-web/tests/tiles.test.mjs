import {test} from 'node:test';
import assert from 'node:assert/strict';
import {periodicPixels,compatibleTile,tileVariant} from '../tiles.mjs';
const size=32,raw=(seed)=>Uint8ClampedArray.from({length:size*size*4},(_,i)=>i%4===3?255:(i*17+seed*37)%256);
function edge(tile,side){return Array.from({length:size*4},(_,i)=>{const p=Math.floor(i/4),c=i%4;return tile[(side==='left'?p*size:side==='right'?p*size+size-1:side==='top'?p:(size-1)*size+p)*4+c]})}
test('periodic textures have identical opposing edges, including corners',()=>{
 for(const profile of ['mean','interior']){
  const input=raw(1),copy=input.slice(),tile=periodicPixels(input,size,size,'xy',8,profile);
  assert.deepEqual(input,copy);assert.deepEqual(edge(tile,'left'),edge(tile,'right'));assert.deepEqual(edge(tile,'top'),edge(tile,'bottom'));
 }
});
test('every terrain variant connects to every other variant in both directions',()=>{
 const canonical=periodicPixels(raw(0),size,size),tiles=Array.from({length:9},(_,i)=>compatibleTile(raw(i),canonical,size,size));
 for(const a of tiles)for(const b of tiles){assert.deepEqual(edge(a,'right'),edge(b,'left'));assert.deepEqual(edge(a,'bottom'),edge(b,'top'));}
 assert.notDeepEqual(tiles[0],tiles[1]);
});
test('horizontal panorama treatment preserves the interior and stays deterministic',()=>{
 const input=raw(3),tile=periodicPixels(input,size,size,'x',4);
 for(let y=0;y<size;y++)assert.deepEqual(tile.slice((y*size+8)*4,(y*size+24)*4),input.slice((y*size+8)*4,(y*size+24)*4));
 for(let x=-25;x<25;x++)assert.ok(tileVariant(x,3)>=0&&tileVariant(x,3)<9);
 assert.equal(new Set(Array.from({length:40},(_,i)=>tileVariant(i,0))).size,9);
});
