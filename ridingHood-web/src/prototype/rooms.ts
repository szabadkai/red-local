export type Point = { x: number; y: number };
export type Platform = { x: number; y: number; w: number; h: number; oneWay?: boolean; motion?: { range: number; period: number }; crumble?: number; sourceIndex?: number };
export type Room = { id: string; chapter: number; hints: string[]; memory: string; name: string; subtitle: string; hint: string; spawn: Point; exit: Point; treasure: Point; platforms: Platform[]; hazard?: { x: number; y: number; range: number; period: number } };
export const ROOMS: Room[] = [
  { id: 'first-clearing', chapter: 0, hints: ['The short stone step gives you a place to start. The lantern is beyond the high island.', 'Feather lifts you higher than a normal jump. Save it until you are on the short step.', 'Jump onto the short step, use Feather while moving right to reach the high island, then jump from its far edge to the lantern.'], memory: 'Grandmother always left a light in the window. Tonight, you will carry one back to her.', name: 'The first clearing', subtitle: 'A little courage goes a long way.', hint: 'That ledge is too high for a jump. Try the Feather.', spawn: {x:78,y:354}, exit:{x:879,y:260}, treasure:{x:596,y:158}, platforms:[
    {x:0,y:354,w:342,h:100},{x:258,y:318,w:84,h:36},{x:398,y:223,w:248,h:200},{x:732,y:260,w:228,h:180}] },
  { id: 'broken-crossing', chapter: 0, hints: ['Look at the far bank. There is room to land if you can cross the water.', 'Step covers distance; Briar can divide the gap into two ordinary jumps.', 'Jump right from the edge and use Step near the top of your jump. Or grow Briar halfway across, slightly above the bank, and jump across in two stages.'], memory: 'The old crossing is gone. The way home does not have to be the way you remember.', name: 'The broken crossing', subtitle: 'There is always another way across.', hint: 'Dash across the gap, or grow yourself a stepping stone.', spawn:{x:76,y:326}, exit:{x:881,y:326}, treasure:{x:435,y:252}, platforms:[
    {x:0,y:326,w:300,h:120},{x:560,y:326,w:400,h:120}] },
  {
    id: 'briar-garden', chapter: 0, name: 'The briar garden', subtitle: 'A place to stand can be a kind of magic.',
    hint: 'Hold Briar to aim. Release to grow a stepping stone; invalid placement keeps your card.',
    hints: ['There are two gaps, but the middle island is safe.', 'Briar can bridge the first gap. Feather offers another way onto the island.', 'From the first bank, grow Briar at the middle of the gap, just above the ground. Jump via it onto the island. Save Step for the final crossing.'],
    memory: 'A thorn catches a red thread. Even the forest remembers her cloak.',
    spawn:{x:72,y:342}, exit:{x:885,y:300}, treasure:{x:500,y:210},
    platforms:[{x:0,y:342,w:240,h:100},{x:420,y:285,w:140,h:150},{x:710,y:300,w:250,h:130}],
  },
  { id: 'lantern-keeper', chapter: 0, hints: ['The little stone post is a stepping stone. Watch the wisp before crossing the last gap.', 'Feather reaches the central island. Keep Step or Briar for the final crossing.', 'Jump onto the small post, use Feather toward the central island, then jump from its right edge and Step above the wisp to the far bank.'], memory: 'Three lights now mark the path. Somewhere beyond the trees, a window waits.', name: 'The lantern keeper', subtitle: 'Choose your moment. Make your own path.', hint: 'The red wisp is dangerous. Pause in the air to plan your way past.', spawn:{x:72,y:350}, exit:{x:880,y:300}, treasure:{x:405,y:151}, platforms:[
    {x:0,y:350,w:220,h:100},{x:252,y:310,w:64,h:160},{x:366,y:265,w:218,h:180},{x:748,y:300,w:212,h:150}] ,hazard:{x:668,y:278,range:64,period:4.2}},

  {
    id: 'millpond', chapter: 1, name: 'The millpond', subtitle: 'Some paths come to meet you.',
    hint: 'The pale raft carries you. Watch its dotted path; pause freezes it too.',
    hints: ['The raft moves back and forth, carrying anyone standing on it.', 'Board it as it approaches the near bank. Ride toward the far side before jumping.', 'Jump from the bank onto the raft when it is nearby. Wait for the raft to reach the right side, then jump toward the far bank. Step can extend that jump.'],
    memory: 'The mill is silent, but its little ferry still knows the way.',
    spawn:{x:75,y:330},exit:{x:885,y:330},treasure:{x:470,y:240},
    platforms:[{x:0,y:330,w:250,h:100},{x:325,y:320,w:115,h:16,oneWay:true,motion:{range:125,period:7}},{x:610,y:330,w:350,h:100}],
  },
  {
    id: 'bell-tower', chapter: 1, name: 'The bell tower', subtitle: 'Listen for the space between the bells.',
    hint: 'The high balcony needs Feather. The raft can bring you closer first.',
    hints: ['The tallest ledge is too high for an ordinary jump.', 'Keep Feather for the balcony. Use the lower ledge or moving raft as your launch point.', 'Jump onto the short step, then use Feather while moving right onto the high balcony. Jump right again and use Step if you need extra distance.'],
    memory: 'A ribbon on the bell rope: Grandmother tied it there to guide you.',
    spawn:{x:70,y:354},exit:{x:884,y:270},treasure:{x:530,y:125},
    platforms:[{x:0,y:354,w:260,h:100},{x:210,y:318,w:90,h:40},{x:345,y:300,w:88,h:14,oneWay:true,motion:{range:35,period:6}},{x:440,y:205,w:210,h:230},{x:770,y:270,w:190,h:160}],
  },
  {
    id: 'lost-street', chapter: 1, name: 'The lost street', subtitle: 'Above the water, another road.',
    hint: 'A low raft and a high terrace offer different ways across.',
    hints: ['The terrace is safe; the wisp patrols the low crossing.', 'Feather takes the high route. Briar can extend the terrace toward the far bank.', 'Jump from the edge, then use Feather toward the high terrace. Cross its length, then jump and Step to the lantern; jump for the keepsake before leaving.'],
    memory: 'The windows are empty. You light a lantern for those who will return.',
    spawn:{x:70,y:340},exit:{x:885,y:310},treasure:{x:530,y:170},
    platforms:[{x:0,y:340,w:255,h:100},{x:380,y:245,w:220,h:18,oneWay:true},{x:320,y:345,w:95,h:14,oneWay:true,motion:{range:80,period:6}},{x:745,y:310,w:215,h:130}],
    hazard:{x:600,y:340,range:65,period:5},
  },
  {
    id: 'ferry-crossing', chapter: 1, name: 'The last ferry', subtitle: 'Carry the light across the water.',
    hint: 'Use the central pier to plan the next crossing. Every card still has only one use.',
    hints: ['The central pier is a safe place between the two crossings.', 'Feather reaches the central pier. Save Step or Briar for the second gap.', 'Jump from the first bank, then use Feather while moving right. Land on the pier, collect the keepsake with a normal jump, then jump and Step over the final gap.'],
    memory: 'Across the water, a warm shape rises between the thorns. Home.',
    spawn:{x:70,y:340},exit:{x:884,y:315},treasure:{x:475,y:190},
    platforms:[{x:0,y:340,w:225,h:100},{x:285,y:330,w:100,h:15,oneWay:true,motion:{range:50,period:6}},{x:405,y:265,w:150,h:170},{x:625,y:325,w:100,h:15,oneWay:true,motion:{range:45,period:5}},{x:780,y:315,w:180,h:130}],
  },
  {
    id: 'courtyard', chapter: 2, name: 'The thorn courtyard', subtitle: 'Not every stone will wait.',
    hint: 'Cracked ledges fall after you land. Their shrinking light shows how much time remains.',
    hints: ['Cracked stone gives you time to jump again, but it will not hold forever.', 'Land, look ahead, and keep moving. Planning pauses the crumbling timer.', 'Jump from the first bank onto the cracked ledge, then jump to the central island before it falls. Use Step for the final gap, or Feather to take a higher route.'],
    memory: 'The gate yields to your touch. Someone has been tending the roses.',
    spawn:{x:70,y:340},exit:{x:884,y:310},treasure:{x:530,y:235},
    platforms:[{x:0,y:340,w:250,h:100},{x:340,y:320,w:90,h:18,oneWay:true,crumble:1.6},{x:485,y:310,w:150,h:125},{x:770,y:310,w:190,h:125}],
  },
  {
    id: 'glasshouse', chapter: 2, name: 'The glasshouse', subtitle: 'Make something that will stay.',
    hint: 'Briar remains for the whole attempt. Cracked stone does not.',
    hints: ['You can create one permanent resting place among the fragile ledges.', 'Use Feather for the high island. Save Briar or Step for the second crossing.', 'Jump from the first bank, then use Feather toward the high island. Jump for the keepsake. Grow Briar in the final gap, or jump and Step straight to the far bank.'],
    memory: 'Under broken glass, a new green shoot reaches for the moon.',
    spawn:{x:70,y:350},exit:{x:885,y:290},treasure:{x:490,y:170},
    platforms:[{x:0,y:350,w:260,h:100},{x:330,y:315,w:75,h:16,oneWay:true,crumble:1.4},{x:420,y:245,w:170,h:190},{x:650,y:275,w:80,h:16,oneWay:true,crumble:1.3},{x:790,y:290,w:170,h:140}],
  },
  {
    id: 'rooftops', chapter: 2, name: 'The moonlit roofs', subtitle: 'A little courage, one last time.',
    hint: 'The wisp follows a rhythm. The cracked roof will wait while you plan.',
    hints: ['The high roof gives you a safe view of the last crossing.', 'Feather reaches the roof; Step carries you above the wisp.', 'Jump from the first bank, then use Feather toward the high roof. Jump for the keepsake, then launch from the roof’s right edge and Step over the wisp.'],
    memory: 'Smoke curls from a chimney. The house was never truly empty.',
    spawn:{x:70,y:350},exit:{x:885,y:300},treasure:{x:505,y:165},
    platforms:[{x:0,y:350,w:250,h:100},{x:300,y:310,w:90,h:16,oneWay:true,motion:{range:30,period:5}},{x:420,y:240,w:170,h:195},{x:650,y:285,w:80,h:16,oneWay:true,crumble:1.6},{x:790,y:300,w:170,h:140}],
    hazard:{x:695,y:300,range:45,period:4.8},
  },
  {
    id: 'hearth', chapter: 2, name: 'The hearth', subtitle: 'Every light you carried led here.',
    hint: 'No new magic. Just the three cards you have learned to trust.',
    hints: ['The cracked step leads to a high, safe island. The lantern waits beyond the last gap.', 'Feather from the step reaches the high island. Keep Step or Briar for the way home.', 'Jump onto the cracked step, then Feather right to the high island. Jump for the keepsake. From the far edge, jump and Step across to the hearth.'],
    memory: 'Grandmother opens the door. “I knew you would find your way.” You set the lantern by the hearth. Outside, small lights shine through the forest.',
    spawn:{x:70,y:350},exit:{x:884,y:280},treasure:{x:530,y:145},
    platforms:[{x:0,y:350,w:245,h:100},{x:300,y:310,w:90,h:18,oneWay:true,crumble:1.8},{x:440,y:220,w:185,h:210},{x:695,y:290,w:80,h:16,oneWay:true,motion:{range:30,period:6}},{x:825,y:280,w:135,h:155}],
  },
];

export const CHAPTERS = [
  {name:'The Lantern Wood', subtitle:'A light to carry', color:0x06131c},
  {name:'The Drowned Village', subtitle:'A road beneath the water', color:0x132e42},
  {name:'The Thorn House', subtitle:'A window waiting', color:0x32162b},
];
