// Authored clearings share the player's measured jump envelope, not a procedural layout.
export const CLEARINGS=[
 {id:'lantern-wood',name:'Lantern Wood',subtitle:'Follow the lights through the old wood.',theme:'wood',
  platforms:[[0,420,620,1],[740,420,700,1],[1560,420,840,1],[150,360,150],[330,300,150],[500,240,150],[870,360,140],[1030,300,150],[1210,240,150],[1660,360,140],[1840,300,140],[2020,240,140],[2200,300,160],
   [2520,420,700,1],[3340,420,620,1],[4080,420,720,1],[2620,360,150],[2800,300,150],[2980,240,150],[3190,300,180],
   [3470,360,140],[3640,300,150],[3810,240,90],[4110,360,120],[4250,300,140],[4420,240,140],[4600,300,160]],
  embers:[[405,282],[2090,222],[3855,222]],checkpoints:[800,1620,2570,3400,4130],gates:[1400,2380,3930],
  enemies:[[430,0],[450,4,'mage'],[940,1,'runner'],[1120,7],[1310,8,1],[1780,2,'runner'],[1930,10,'mage'],[2110,11,1],
   [2700,13,'runner'],[2880,17,'mage'],[3080,13],[3520,14],[3700,21,'mage'],[3860,14,'runner'],
   [4200,15,'runner'],[4320,24,'mage'],[4500,15,1],[4640,15]],
  npcs:[[112,0,'mother','Straight to Grandmother\'s, Red.']],
  exit:{x:4710,y:300},finish:'The first lantern wakes. Beyond the trees, the old crossing waits.'},
 {id:'broken-crossing',name:"The Huntsman's Bridge",subtitle:'Across the arches, beneath the roots.',theme:'bridge',
  platforms:[[0,420,240,1,'bank'],[200,360,660,0,'bridge'],[900,420,500,1,'bank'],[1480,420,1220,1,'bank'],
   [120,360,110,0,'ruin'],[260,300,150,0,'ruin'],[430,240,230,0,'branch'],[690,300,190,0,'branch'],
   [260,460,390,0,'lower'],[660,420,180,0,'root'],[980,360,160,0,'ruin'],[1140,300,160,0,'ruin'],
   [1310,240,190,0,'branch'],[1510,300,180,0,'branch'],[1690,360,170,0,'root'],
   [1850,300,170,0,'ruin'],[2030,240,170,0,'branch'],[2200,300,190,0,'ruin'],
   [2660,360,660,0,'bridge'],[3360,420,560,1,'bank'],[4040,420,760,1,'bank'],[2580,360,110,0,'ruin'],[2720,300,150,0,'ruin'],
   [2890,240,230,0,'branch'],[3150,300,190,0,'branch'],[2720,460,390,0,'lower'],[3120,420,180,0,'root'],
   [3440,360,160,0,'ruin'],[3620,300,160,0,'ruin'],[3790,240,90,0,'ruin'],[4100,360,150,0,'root'],
   [4270,300,150,0,'ruin'],[4440,240,150,0,'branch'],[4610,300,170,0,'ruin']],
  embers:[[535,222],[2115,222],[3005,222]],checkpoints:[960,1540,2040,3420,4090],gates:[1305,2440,3900],
  enemies:[[570,1,'guard'],[785,7,'mage'],[1070,2,'runner'],[1230,2,'runner'],[1405,12,'mage'],[1740,3,'guard'],[1940,15,'runner'],[2120,16,'mage'],
   [2960,18,'guard'],[3230,24,'mage'],[2900,25,'runner'],[3500,19,'runner'],[3700,28,'mage'],[3800,19,'guard'],
   [4180,20,'guard'],[4345,31,'mage'],[4520,20,'runner'],[4660,20,'runner']],
  npcs:[[150,0,'woodcutter','The arches won\'t hold me. Mind your step.']],
  exit:{x:4700,y:300},finish:'Light runs through the broken arches. Beneath the crossing, blue lamps mark a path through the roots.'},
 {id:'moss-cavern',name:'Moss Cavern',subtitle:'Follow the blue lamps beneath the roots.',theme:'cave',
  platforms:[[0,420,460,1],[580,420,600,1],[1300,420,500,1],[1920,420,480,1],[120,360,160],[300,300,160],[620,360,150],[790,300,150],[960,240,160],[1360,360,150],[1530,300,150],[1700,240,160],[2000,360,150],[2180,300,190],
   [2520,420,420,1],[3060,420,540,1],[3720,420,380,1],[4220,420,580,1],[2600,360,150],[2780,300,160],[2960,240,180],
   [3180,300,150],[3380,360,150],[3800,360,150],[3980,300,150],[4160,240,160],[4400,360,150],[4580,300,200]],
  embers:[[380,402],[1770,222],[4240,222]],checkpoints:[620,1340,1960,2560,3100,3760,4260],gates:[1160,2385,3580],
  enemies:[[310,0,'runner'],[710,1,'runner'],[865,7,'mage'],[1050,8,'runner'],[1420,2,'guard'],[1770,11,'mage'],[2050,3,'runner'],[2260,13,'mage'],
   [2650,14,'runner'],[2860,19,'mage'],[3050,20,'runner'],[3250,15,'guard'],[3450,22,'mage'],
   [3850,16,'runner'],[4050,24,'mage'],[4300,17,'guard'],[4470,26,'runner'],[4650,17,'runner']],
  exit:{x:4700,y:300},finish:'The roots loosen. Above the cavern, an old bell calls through the stone.'},
 {id:'ruined-chapel',name:'Ruined Chapel',subtitle:'Silence the watchers beneath the broken bell.',theme:'chapel',
  platforms:[[0,420,620,1],[740,420,680,1],[1540,420,1380,1],[160,360,150],[330,300,150],[500,240,160],[800,360,150],[970,300,150],[1140,240,160],[1620,360,150],[1790,300,150],[1960,240,160],[2180,300,190],
   [3040,420,700,1],[3860,420,940,1],[2500,360,150],[2680,300,150],[2860,240,240],[3140,240,200],[3380,300,150],[3550,360,140],
   [3980,360,150],[4160,300,150],[4340,240,180],[4570,300,200]],
  embers:[[575,222],[2035,222],[3240,222]],checkpoints:[790,1590,3090,3910],gates:[1395,2430,3715],
  enemies:[[430,0,'guard'],[405,4,'mage'],[885,1,'runner'],[1100,1,'guard'],[1210,8,'mage'],[1700,2,'guard'],[1880,10,'runner'],[2040,11,'mage'],
   [2580,2,'runner'],[2760,16,'mage'],[2980,17,'guard'],[3200,13,'guard'],[3450,19,'mage'],[3620,13,'runner'],
   [4050,14,'guard'],[4230,22,'mage'],[4430,23,'mage'],[4400,14,'runner'],[4640,14,'guard']],
  exit:{x:4690,y:300},finish:'The bell is quiet. Beyond the chapel, one house still waits for its fire.'},
 {id:'thorn-house',name:'Thorn House',subtitle:'Bring the three lost flames back to the hearth.',theme:'house',
  platforms:[[0,420,600,1],[740,420,660,1],[1540,420,860,1],[140,360,150],[310,300,150],[480,240,160],[850,360,150],[1020,300,150],[1190,240,160],[1650,360,150],[1820,300,150],[1990,240,160],[2190,300,180],
   [2520,420,460,1],[3100,420,400,1],[3620,420,460,1],[4200,420,600,1],[2600,360,150],[2780,300,150],[2960,240,160],
   [3180,300,140],[3350,360,130],[3700,360,150],[3880,300,150],[4250,360,140],[4420,300,130],[4590,300,180]],
  embers:[[385,282],[2065,222],[3040,222]],checkpoints:[790,1600,2570,3150,3670,4250],gates:[1380,2385,4060],
  enemies:[[350,0,'runner'],[385,4,'mage'],[920,1,'guard'],[1090,7],[1300,8,'mage'],[1740,2,'runner'],[1880,10,'mage'],[2070,11,'guard'],[2250,2],
   [2650,13,'runner'],[2850,18,'mage'],[3040,19],[3250,14,'guard'],[3750,15,'runner'],[3950,23,'mage'],[3900,15,'guard'],
   [4300,16],[4480,25,'mage'],[4560,16,'guard'],[4380,16,'runner']],
  npcs:[[4614,26,'grandmother','There you are, dear. Bring the flames in.']],
  exit:{x:4710,y:300},finish:'The hearth catches. Through the trees, every lantern answers. Red is home.'}
];
// Each clearing is two screens-worth of trail in four gated sections.
export const TRAIL_WIDTH=4800;
export function platformsFor(index=0){return CLEARINGS[index].platforms.map(([x,y,w,ground,kind],id)=>({x,y,w,ground:!!ground,id,...(kind?{kind}:{})}));}
export const SAVE_KEY='red.poker.journey.v2';
export function loadJourney(storage){
 try{
  let save=JSON.parse(storage.getItem(SAVE_KEY));
  if(!save){
   const old=JSON.parse(storage.getItem('red.poker.journey.v1'));
   if(!old||old.version!==1||!Number.isInteger(old.stage)||old.stage<0||old.stage>2)return null;
   // Preserve the old destination, discard the removed upgrade system.
   save={version:2,clearing:['lantern-wood','broken-crossing','thorn-house'][old.stage],complete:old.complete===true&&old.stage===2};
  }
  const stage=CLEARINGS.findIndex(c=>c.id===save.clearing);
  if(save.version!==2||stage<0)return null;
  return {stage,complete:save.complete===true&&stage===CLEARINGS.length-1};
 }catch{return null;}
}
export function saveJourney(storage,world){
 if(world.practice)return false;
 try{storage.setItem(SAVE_KEY,JSON.stringify({version:2,clearing:world.clearing.id,complete:world.mode==='won'&&world.stageIndex===CLEARINGS.length-1}));return true;}catch{return false;}
}
