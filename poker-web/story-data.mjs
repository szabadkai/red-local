// Authored dialogue and encounter layouts. Story state lives in story.mjs.
export const CAST={
 red:{name:'Red',role:'A basket, a blade, a borrowed deck',color:'#df7773'},
 mother:{name:'Mother',role:'At the village gate',color:'#e6c591'},
 grandma:{name:'Grandmother',role:'Keeper of the forest roads',color:'#e6c591'},
 stranger:{name:'The stranger',role:'A familiar voice in the trees',color:'#aab6c7'},
 pip:{name:'Pip',role:'Ferryman. Very reasonable rates.',color:'#b8cb84'},
 rowan:{name:'Rowan',role:'The Huntsman',color:'#b9c9c5'},
 wren:{name:'Sister Wren',role:'Keeper of the chapel bell',color:'#b7b4e3'},
 wolf:{name:'The Wolf',role:'Keeper of stolen voices',color:'#d99494'},
 hart:{name:'The Briar Hart',role:'A wounded guardian',color:'#c6bc89'},
 tollkeeper:{name:'The Tollkeeper',role:'Bound to the mill',color:'#d0ae7e'},
 widow:{name:'The Bell Widow',role:'Silence in the belfry',color:'#b9add3'}
};
const line=(speaker,text)=>({speaker,text});
const scene=(title,caption,cast,lines)=>({title,caption,cast,lines:lines.map(([who,text])=>line(who,text))});
export const SCENES={
 prologue:scene('The empty letter','A letter without a word. A loaf still warm.',['mother','red'],[
 ['mother','Your grandmother has never sent me a short letter. This is a first.'],
 ['red','Perhaps she finally ran out of complaints.'],
 ['mother','Take her medicine, the bread, and these cards. She taught you for a reason.'],
 ['red','To beat her at cards?'],
 ['mother','Nobody beats her at cards. Home before dark. Stay by the lanterns. Find a face before you follow a voice.'],
 ['mother',"And don't leave the crusts."],
 ['red','I know. “The crust is what holds the bread together.”']]),
 stranger:scene('The helpful stranger','A white flower. A sign pointing away from the lanterns.',['stranger','red'],[
 ['stranger','Taking supper somewhere?'],['red','Medicine. The bread is for complaints.'],
 ['stranger',"The old woman beyond the chapel, then. Her garden is lovely this time of year."],
 ['red','You know her?'],['stranger','Everyone in these woods knows your grandmother. The shorter path is over here.'],
 ['red',"Something's hurt on the lantern road. I'm going to look."]]),
 hartIntro:scene('A wounded guardian','An iron trap. Thorns wound tight around living antlers.',['red','hart'],[
 ['red',"Easy. I'm not here to hurt you."],['red',"That trap's pulling the thorns tighter. I'll have to break it loose."]]),
 hartOutro:scene('The road remembers','The trap breaks. The Hart bows its head and the thorns part.',['red','hart'],[
 ['red',"There. You can go."],['red',"No, you can't have the bread. That loaf's spoken for."]]),
 pip:scene('A very reasonable toll','An overturned bucket. A ferry scarcely bigger than its captain.',['pip','red'],[
 ['pip',"Toll's one loaf."],['red','For that boat?'],['pip',"You're paying for the captain."],
 ['mother','Red? This way. Into the mill.'],['red',"She doesn't know I'm here."],['pip',"It used my brother's voice yesterday."]]),
 tollIntro:scene('The other toll collector','The waterwheel turns against the current. A chain pulls taut.',['pip','red','tollkeeper'],[
 ['pip',"That's the mill guard. Something locked him inside his own armor."],
 ['red','Then we break the lock.'],['pip',"Mind the hook. It's bigger than the boat."]]),
 tollOutro:scene('The last light','Across the river, the cottage window goes dark.',['pip','red'],[
 ['pip',"That was the old keeper's light."],['red','Row faster.'],['pip','I am rowing faster.'],
 ['pip',"The upper road's gone. Quarry tunnel comes out by the chapel. Find Rowan. Big axe. Terrible manners."],
 ['red','Here. A piece of bread. For the captain.']]),
 cavern:scene('Do not answer','Hunter marks on the stone: DO NOT ANSWER. IT KNOWS YOUR NAME.',['red'],[
 ['red',"Mother said find a face before following a voice. Down here, I'd settle for footprints."],
 ['rowan','Stay back!'],['red',"That's a face. And an axe."]]),
 rowanIntro:scene('The wrong shadow',"Red's shadow moves after she stops.",['rowan','red'],[
 ['rowan','Put down the basket. Step away from the cloak.'],['red','You first. From the axe.'],
 ['wolf','Too late, Huntsman.'],['red',"That wasn't me."],['rowan','It never is.']]),
 rowanOutro:scene('A useful apology','The axe catches in a root. Red cuts down the shadow behind Rowan.',['rowan','red'],[
 ['rowan','You could have left me to it.'],['red','I still need directions.'],
 ['rowan','Your grandmother made that cloak. She used to mend mine.'],['red','Then help me find her.'],
 ['rowan',"The chapel bell shakes loose the voices he's taken. Something up there keeps it silent."],
 ['red',"We'll try from this side."],['rowan',"I'll hold this passage. Get to the bell."]]),
 chapel:scene('A rhythm in the silk','Someone taps from the belfry. Three knocks. A pause. Three knocks.',['wren','red'],[
 ['red','Someone is up there.'],['red',"I'll get the lanterns burning. Hold on."]]),
 widowIntro:scene('The bell keeper','A captive keeper points upward. The wooden supports unfold into legs.',['wren','red','widow'],[
 ['red','You want it rung?'],['red',"Then let's clear away the cobwebs."]]),
 widowOutro:scene('A voice from the house','The bell rings. Pale silk falls like snow.',['wren','red'],[
 ['grandma',"Red? If that's you, mind the back step. It's rotten."],['red',"She's alive."],
 ['wren','Inside him. The bell made him loose his grip. Only for a moment.'],
 ['wren',"I'll keep ringing. Bring her out."]]),
 house:scene('The cottage at the end','White flowers choke the garden. Rowan lifts his axe at the gate.',['rowan','red'],[
 ['rowan',"I'll cut the thorns away. You'll have a way back out."],['red',"Keep it wide enough for two."],
 ['rowan','Three. Nobody stays behind.']]),
 wolfIntro:scene('Grandmother in bed','The spectacles sit crookedly. The basket stays just out of reach.',['grandma','red'],[
 ['grandma','Come closer, little one. Let me see you.'],['red','What big ears you have.'],
 ['grandma','All the better to hear you coming.'],['red','And what big hands.'],
 ['grandma','All the better to hold you.'],['red','Shall I cut off the crusts?'],
 ['grandma','Yes, dear. I never liked them.'],['red','Where is she?'],
 ['wolf','You came such a long way. Surely you knew what was at the end.']]),
 swallowed:scene('Swallowed','A hand reaches from the hearth shadow. Red holds on.',['wolf','red'],[
 ['wolf','Everything that comes into my woods ends up with me.'],['red',"Then that's where I'm going."]]),
 inside:scene('Rooms he has swallowed','A kitchen, a chapel, a mill. Grandmother is bound to her chair.',['grandma','red'],[
 ['grandma','Did you bring the medicine?'],['red','You could have mentioned the wolf in your letter.'],
 ['grandma','I tried. He ate the words.'],['grandma','Cut the three knots. Listen for the bell. It shows where the shadows can reach.']]),
 garden:scene('Follow the red thread','Grandmother pulls a red stitch from her hem. It catches a crack of daylight.',['grandma','red','rowan'],[
 ['grandma',"There. Cut along the seam. I'll follow."],['rowan','The gate is open!'],
 ['red',"Go. He's still holding the road."],['grandma',"And you've still got my cards."]]),
 breakfast:scene('Breakfast','The Wolf is ash and pale fur. The cottage is only a cottage again.',['grandma','red','rowan'],[
 ['grandma','Still tastes like ditch water.'],['red','Mother says to finish it.'],
 ['grandma','I thought I could keep the road safe by myself.'],['red','Runs in the family.'],
 ['red',"The bread's ruined."],['grandma','Tastes like bread.']]),
 epilogue:scene('Room for one more','Dawn. The ferry waits. Four mismatched cups wait at home.',['mother','red','grandma','pip'],[
 ['mother','I said before dark.'],['red','We brought breakfast.'],['pip',"Return crossing's on the captain."],
 ['grandma',"Come along. There's enough to share."]])
};
export const STAGES=[
 {encounter:'stranger',intro:'hartIntro',outro:'hartOutro',boss:'hart',title:'The Briar Hart',objective:'Bring the basket to Grandmother',hint:'Bait the charge. Strike while the Hart catches its breath.'},
 {encounter:'pip',intro:'tollIntro',outro:'tollOutro',boss:'tollkeeper',title:'The Tollkeeper',objective:'Find a crossing with Pip',hint:'Jump the chain sweep. Move away from the raised hook.'},
 {encounter:'cavern',intro:'rowanIntro',outro:'rowanOutro',boss:'rowan',title:'Rowan the Huntsman',objective:'Find the Huntsman beneath the roots',hint:'Bait his axe. Strike during recovery, while his guard is down.'},
 {encounter:'chapel',intro:'widowIntro',outro:'widowOutro',boss:'widow',title:'The Bell Widow',objective:'Reach the bell keeper',hint:'Watch the falling silk. Jump the low rings of sound.'},
 {encounter:'house',intro:'wolfIntro',outro:'breakfast',boss:'wolf',title:'The Wolf',objective:"Reach Grandmother's bedroom",hint:'Dodge the bite. Strike after his leap lands.'}
];
const platform=(id,x,y,w,ground=false)=>({id,x,y,w,ground});
export function arenaPlatforms(stage,location='arena'){
 if(location==='inside')return [platform(0,0,420,960,true),platform(1,150,360,180),platform(2,340,300,180),platform(3,530,240,180),platform(4,730,300,180)];
 const ledges=[[[140,360,160],[650,360,170]],[[100,360,170],[680,360,170]],[[180,360,150],[620,360,150]],[[120,360,180],[660,360,180]],[[100,360,180],[680,360,180]]][stage];
 return [platform(0,0,420,960,true),...ledges.map(([x,y,w],i)=>platform(i+1,x,y,w))];
}
