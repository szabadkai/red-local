import {test} from 'node:test';
import assert from 'node:assert/strict';
import {World} from '../model.mjs';
import {CLEARINGS,SAVE_KEY,loadJourney,saveJourney} from '../journey.mjs';
const step=(w,n,input={})=>{for(let i=0;i<n;i++)w.step(1/60,input)};
function travel(w,target,jump=false,dash=false){
 if(jump)w.jump();if(dash)w.startDash();
 for(let i=0;i<240;i++){
  const d=target-w.x;w.step(1/60,{axis:Math.abs(d)<1?0:Math.max(-1,Math.min(1,d/22))});
  if(w.mode==='won')return;
  if(Math.abs(d)<4&&Math.abs(w.vx)<10&&w.grounded)return;
  assert.equal(w.mode,'playing');
 }
 assert.fail(`Failed to reach ${target} from ${w.x},${w.y}`);
}
const routes=[
 [125,[220],285,[405],465,[570],[790,true],850,[940],998,[1100],1165,[1280],1345,[1620,true],1640,[1730],1788,[1910],1968,[2090],2140,[2250],2340,[2540,true],2580,[2680],2745,[2860],2925,[3040],3105,[3240],3345,[3480],3585,[3700],3765,[3855],3880,[4100,true],[4170],4210,[4320],4365,[4490],4540,[4660],4710],
 [100,[175],220,[335],390,[535],645,[770],825,[960],970,[1060],1110,[1220],1280,[1405],1470,[1595],1650,[1775],1800,[1935],1980,[2115],2180,[2290],2370,[2480],2540,[2620],2700,[2790],2850,[2960],3100,[3220],3320,[3420],3400,[3500],3590,[3680],3760,[3840],3860,[4070,true],4080,[4160],4230,[4330],4400,[4500],4570,[4680],4700],
 [120,[215],275,[385],445,[560],620,[790,true],830,[925],985,[1095],1155,[1265],1330,[1600,true],1630,[1725],1785,[1895],1955,[2065],2130,[2270],2350,[2550,true],2570,[2660],2730,[2840],2910,[3040],3100,[3230],3300,[3410],3460,[3640,true],3670,[3760],3830,[3940],4010,[4230,true],[4310],4370,[4470],4530,[4640],4710]
];
routes.splice(2,0,
 [380,440,[600],600,[695],755,[865],925,[1030],1100,[1340,true],1345,[1435],1490,[1605],1660,[1770],1780,[1950,true],1980,[2075],2135,[2255],2350,[2550,true],2570,[2660],2730,[2840],2920,[3030],3120,[3240],3310,[3430],3510,3585,[3745],3770,[3860],3930,[4040],4110,[4240],4300,[4440],4530,[4640],4700],
 [130,[235],295,[405],465,[575],620,[790,true],1100,1405,[1590],1600,[1695],1755,[1865],1925,[2035],2095,[2260],2350,[2460],2470,[2560],2630,[2740],2810,[2920],3080,[3200],3320,[3440],3510,[3610],3725,[3885],3930,[4040],4110,[4220],4290,[4400],4500,[4620],4690]
);
for(let stage=0;stage<CLEARINGS.length;stage++)test(`${CLEARINGS[stage].name}: complete route without upgrades, damage or falls`,()=>{
 const w=new World();w.reset(stage);w.enemies=[];
 for(const instruction of routes[stage]){if(Array.isArray(instruction))travel(w,instruction[0],true,!!instruction[1]);else travel(w,instruction);}
 assert.equal(w.collected,3);assert.equal(w.mode,'won');assert.equal(w.fallCount,0);assert.equal(w.health,5);
});
test('clearing completion advances directly once and retry restores the current stage',()=>{
 const w=new World();assert.equal(w.advance(),false);
 for(let stage=1;stage<CLEARINGS.length;stage++){
  w.mode='won';assert.equal(w.advance(),true);assert.equal(w.stageIndex,stage);
  assert.equal(w.mode,'playing');assert.equal(w.health,5);assert.equal(w.deck.hand.length,5);assert.equal(w.advance(),false);
  w.health=1;w.retry();assert.equal(w.stageIndex,stage);assert.equal(w.health,5);
 }
 w.mode='won';assert.equal(w.advance(),false);assert.equal('keepsakes' in w,false);
});
test('journey persists stable clearing IDs and leaves practice progress untouched',()=>{
 const memory=new Map(),storage={getItem:k=>memory.get(k)??null,setItem:(k,v)=>memory.set(k,v)},w=new World();
 assert.equal(loadJourney(storage),null);w.reset(4);w.mode='won';assert.equal(saveJourney(storage,w),true);
 assert.deepEqual(loadJourney(storage),{stage:4,complete:true});assert.equal(JSON.parse(memory.get(SAVE_KEY)).clearing,'thorn-house');
 w.practiceDeal(7);assert.equal(saveJourney(storage,w),false);assert.equal(loadJourney(storage).stage,4);
 for(const raw of ['bad','null',JSON.stringify({version:2,clearing:'missing'}),JSON.stringify({version:3,clearing:'thorn-house'})]){memory.set(SAVE_KEY,raw);assert.equal(loadJourney(storage),null)}
 const blocked={getItem(){throw Error('blocked')},setItem(){throw Error('blocked')}};assert.equal(loadJourney(blocked),null);assert.equal(saveJourney(blocked,new World()),false);
});
test('legacy journeys keep their destination and discard removed upgrades',()=>{
 for(let oldStage=0;oldStage<3;oldStage++){
  const storage={getItem:key=>key===SAVE_KEY?null:JSON.stringify({version:1,stage:oldStage,keepsakes:['feather','briar'],complete:true})};
  assert.deepEqual(loadJourney(storage),{stage:[0,1,4][oldStage],complete:oldStage===2});
 }
});
test('environment exploration uses authored terrain without saving or advancing',()=>{
 for(const [kind,stage] of [[7,2],[8,3],[9,1]]){
  const w=new World();w.practiceDeal(kind);assert.equal(w.practice,true);assert.equal(w.arena,false);assert.equal(w.stageIndex,stage);
  assert.ok(w.platforms.length>10);w.mode='won';assert.equal(w.advance(),false);
  assert.equal(saveJourney({setItem(){assert.fail('practice must not save')}},w),false);
 }
});

test('bridge lower passage reconnects with the main route without a fall',()=>{
 const w=new World();w.reset(1);w.enemies=[];
 travel(w,100);travel(w,175,true);travel(w,480);
 assert.equal(w.y,360);w.dropDown();step(w,45);
 assert.equal(w.y,460);travel(w,620);travel(w,730,true);assert.equal(w.y,420);
 travel(w,810);travel(w,970,true);assert.equal(w.y,420);
 assert.equal(w.fallCount,0);assert.equal(w.health,5);
});

test('briar gates hold until the section is cleared, then heal a heart and stay open across a retry',()=>{
 const w=new World(),gate=CLEARINGS[0].gates[0];
 const beyond=w.enemies.find(e=>e.section===1),hp=beyond.hp;
 w.x=gate-40;w.y=420;w.health=3;step(w,60,{axis:1});
 assert.ok(w.x<gate,'the closed gate stops Red');assert.equal(w.gates[0].open,false);
 w.damage(beyond,5,0);assert.equal(beyond.hp,hp,'foes behind the gate cannot be hit through it');
 w.enemies=w.enemies.filter(e=>e.section>0);step(w,1);
 assert.equal(w.gates[0].open,true);assert.equal(w.health,4);assert.equal(w.gates[1].open,false);
 step(w,20,{axis:1});assert.ok(w.x>gate);
 w.retry();assert.equal(w.gates[0].open,true);assert.equal(w.x,gate-40);assert.equal(w.health,5);
 assert.ok(w.enemies.length&&w.enemies.every(e=>e.section>0));
});
test('the way on stays shut while foes remain in the clearing',()=>{
 const w=new World();w.gates.forEach(g=>g.open=true);w.enemies=w.enemies.slice(-1);
 w.collected=3;w.embers=[];w.x=w.clearing.exit.x;w.y=w.clearing.exit.y;step(w,1);assert.equal(w.mode,'playing');
 w.enemies=[];step(w,1);assert.equal(w.mode,'won');
});
