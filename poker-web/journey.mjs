// Authored clearings share the player's measured jump envelope, not a procedural layout.
export const CLEARINGS=[
 {id:'lantern-wood',name:'Lantern Wood',subtitle:'Follow the lights through the old wood.',theme:'wood',
  platforms:[[0,420,620,1],[740,420,700,1],[1560,420,840,1],[150,360,150],[330,300,150],[500,240,150],[870,360,140],[1030,300,150],[1210,240,150],[1660,360,140],[1840,300,140],[2020,240,140],[2200,300,160]],
  embers:[[405,282],[1280,222],[2090,222]],checkpoints:[800,1620],
  enemies:[[430,0],[450,4],[940,1,'runner'],[1120,7],[1310,8,1],[1780,2,'runner'],[2110,11,1]],
  exit:{x:2310,y:300},finish:'The first lantern wakes. Beyond the trees, the old crossing waits.'},
 {id:'broken-crossing',name:"The Huntsman's Bridge",subtitle:'Across the arches, beneath the roots.',theme:'bridge',
  platforms:[[0,420,240,1,'bank'],[200,360,660,0,'bridge'],[900,420,500,1,'bank'],[1480,420,920,1,'bank'],
   [120,360,110,0,'ruin'],[260,300,150,0,'ruin'],[430,240,230,0,'branch'],[690,300,190,0,'branch'],
   [260,460,390,0,'lower'],[660,420,180,0,'root'],[980,360,160,0,'ruin'],[1140,300,160,0,'ruin'],
   [1310,240,190,0,'branch'],[1510,300,180,0,'branch'],[1690,360,170,0,'root'],
   [1850,300,170,0,'ruin'],[2030,240,170,0,'branch'],[2200,300,190,0,'ruin']],
  embers:[[535,222],[1220,282],[2115,222]],checkpoints:[960,1540,2040],
  enemies:[[570,1,'guard'],[785,7,'mage'],[1070,2,'runner'],[1405,12,'mage'],[1740,3,'guard'],[1940,15,'runner']],
  exit:{x:2310,y:300},finish:'Light runs through the broken arches. Beneath the crossing, blue lamps mark a path through the roots.'},
 {id:'moss-cavern',name:'Moss Cavern',subtitle:'Follow the blue lamps beneath the roots.',theme:'cave',
  platforms:[[0,420,460,1],[580,420,600,1],[1300,420,500,1],[1920,420,480,1],[120,360,160],[300,300,160],[620,360,150],[790,300,150],[960,240,160],[1360,360,150],[1530,300,150],[1700,240,160],[2000,360,150],[2180,300,190]],
  embers:[[380,402],[1030,222],[1770,222]],checkpoints:[620,1340,1960],
  enemies:[[310,0,'runner'],[710,1,'runner'],[865,7,'mage'],[1050,8,'runner'],[1420,2,'guard'],[1770,11,'mage'],[2050,3,'runner']],
  exit:{x:2310,y:300},finish:'The roots loosen. Above the cavern, an old bell calls through the stone.'},
 {id:'ruined-chapel',name:'Ruined Chapel',subtitle:'Silence the watchers beneath the broken bell.',theme:'chapel',
  platforms:[[0,420,620,1],[740,420,680,1],[1540,420,860,1],[160,360,150],[330,300,150],[500,240,160],[800,360,150],[970,300,150],[1140,240,160],[1620,360,150],[1790,300,150],[1960,240,160],[2180,300,190]],
  embers:[[575,222],[1100,402],[2035,222]],checkpoints:[790,1590],
  enemies:[[430,0,'guard'],[405,4,'mage'],[885,1,'runner'],[1100,1,'guard'],[1210,8,'mage'],[1700,2,'guard'],[2040,11,'mage']],
  exit:{x:2310,y:300},finish:'The bell is quiet. Beyond the chapel, one house still waits for its fire.'},
 {id:'thorn-house',name:'Thorn House',subtitle:'Bring the three lost flames back to the hearth.',theme:'house',
  platforms:[[0,420,600,1],[740,420,660,1],[1540,420,860,1],[140,360,150],[310,300,150],[480,240,160],[850,360,150],[1020,300,150],[1190,240,160],[1650,360,150],[1820,300,150],[1990,240,160],[2190,300,180]],
  embers:[[385,282],[1265,222],[2065,222]],checkpoints:[790,1600],
  enemies:[[350,0,'runner'],[385,4,'mage'],[920,1,'guard'],[1090,7],[1300,8,'mage'],[1740,2,'runner'],[1880,10,'mage'],[2070,11,'guard']],
  exit:{x:2310,y:300},finish:'The hearth catches. Through the trees, every lantern answers. Red is home.'}
];
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
