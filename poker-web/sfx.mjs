// Sound effects, synthesised by chip.mjs like the music (syntax: the header of chip.mjs).
// Each is a tiny song at tempo 150 (a quarter note is 0.4 s); `gain` balances it against the others.
const fx=(gain,text)=>({gain,text:'tempo 150\n'+text});
export const SFX={
 // movement
 jump:fx(.7,`
inst hop wave=p pw=25-45/4 slide=-9/7 adsr=0,9,0,2
inst air wave=n adsr=0,4,0,1 filter=hp cut=3000 res=0.2
a: @hop v12 o5 e16 r16
b: @air v4 o6 c32 r16.`),
 dash:fx(.8,`
inst whoosh wave=n adsr=1,10,0,3 filter=bp cut=600>3800/380 res=0.6
inst zip wave=s slide=12/8 adsr=0,8,0,2 filter=lp cut=3000 res=0.3
a: @whoosh v12 o5 c8 r16
b: @zip v6 o5 c16 r8`),
 land:fx(.6,`
inst thud wave=n,t arp=24,0,-5,-9,-12 adsr=0,6,0,1
a: @thud v9 o2 g16 r16`),
 // combat
 attack1:fx(.8,`
inst swish wave=n adsr=0,7,0,2 filter=bp cut=1200>5000/700 res=0.55
inst edge wave=p pw=12 slide=7/6 ring=1.5 adsr=0,5,0,1
a: @swish v13 o6 c16 r16
b: @edge v5 o6 a32 r16.`),
 hit:fx(.9,`
inst smack wave=n,p,p arp=24,7,0,-5 pw=40 adsr=0,5,0,1
inst crack wave=n adsr=0,3,0,1 filter=hp cut=2000 res=0.3
a: @smack v13 o3 a16 r16
b: @crack v9 o6 c32 r16.`),
 attack3:fx(1,`
inst zap wave=p,s,p arp=12,7,0,-5 pw=20-60/6 ring=2.01 adsr=0,10,0,3
inst swish wave=n adsr=0,10,0,3 filter=bp cut=900>4500/400 res=0.55
inst boom wave=n,t arp=19,0,-7,-12,-17 adsr=0,9,0,2
a: @zap v11 o5 e8 r8
b: @swish v10 o6 c8 r8
c: @boom v8 o2 a8 r8`),
 enemy_death:fx(.8,`
inst pop wave=n,t,t,n arp=31,12,5,0,-7 adsr=0,10,0,3
inst puff wave=n adsr=0,12,0,4 filter=bp cut=2500>500/200 res=0.5
a: @pop v11 o3 e8 r8
b: @puff v9 o5 c8 r8`),
 player_hurt:fx(1,`
inst ouch wave=n,s,s,p arp=12,0,-2,-4,-7,-9,-12 pw=30 adsr=0,12,0,2
inst crunch wave=n adsr=0,6,0,1 filter=lp cut=3000>400/300 res=0.4
a: @ouch v13 o4 a8 r16
b: @crunch v10 o5 c16 r8`),
 transform_dark:fx(1,`
inst rise wave=s slide=-24/28 vib=0.6 adsr=0,0,13,10 filter=lp cut=300>3500/90 res=0.8
inst roar wave=n adsr=4,0,10,14 filter=bp cut=300>2200/50 res=0.7
inst toll wave=t ring=2.76 adsr=0,45,0,20
a: @rise v13 o3 d2 r4
b: @roar v9 o4 c2 r4
c: r4. @toll v8 o4 d4 r8`),
 // cards, pickups, lanterns
 meter_full:fx(.6,`
inst blip wave=p arp=12,0 pw=25 adsr=0,10,0,4
inst sheen wave=t detune=7 adsr=0,12,0,6
a: @blip v10 o6 e16 a8 r8
b: @sheen v5 o7 e16 a8 r8`),
 pickup_essence:fx(.7,`
inst spark wave=t,p arp=12,0 pw=15 adsr=0,8,0,5
inst sheen wave=t detune=7 adsr=0,12,0,6
a: @spark v9 o6 l32 c e g >c e8< r8
b: @sheen v4 o5 l32 r c e g >c e8< r16.`),
 checkpoint:fx(.8,`
inst bell wave=t ring=2.76 adsr=0,50,0,40
inst glow wave=p arp=12,0 pw=20-50/2 adsr=2,20,0,20
a: @bell v10 o5 g8 >d4< r2
b: @glow v6 o4 r8 {gb>d}4 r2`),
 // music stingers, played by music.mjs when the track changes
 boss_intro:fx(1.3,`
inst hit wave=n,p arp=36,12,7,0,-5,-9,-12,-14,-17,-19 pw=50 adsr=0,24,0,6
inst crash wave=n adsr=0,40,0,20 filter=hp cut=2500 res=0.2
inst dread wave=s detune=-10 adsr=0,0,12,20 filter=lp cut=200>900/20 res=0.8
a: @hit v15 o2 d2 r2
b: @crash v8 o7 c2 r2
c: @dread v12 o1 d1`),
 // the opening of Red's theme, as a fanfare
 victory:fx(1.3,`
inst fan wave=s,p pw=40-55/1 vib=0.2 adsr=0,14,11,8
inst arp wave=p arp=12,0 pw=10-45/1 adsr=0,12,7,10
inst bass wave=p pw=15-60/1.5 adsr=0,10,10,6 filter=lp cut=300>1800/60 res=0.7
a: @fan v13 o5 g16 b16 >d8 g2< r4
b: @arp v9 o4 r4 {gb>d}2 r4
c: @bass v12 o2 g4 g2 r4`),
};
