// All simulation state lives here. Rendering and UI never advance gameplay time.
export const BALANCE = { width: 960, height: 420, speed: 176, gravity: 850, jump: 290,
  feather: 510, dashSpeed: 690, dashDuration: .34, playerWidth: 18, playerHeight: 30,
  briarWidth: 112, briarReach: 205, coyote: .1, jumpBuffer: .13, step: 1 / 120 };
export type Card = 'feather' | 'step' | 'briar';
export type Point = { x: number; y: number };
export type Platform = { x: number; y: number; w: number; h: number; oneWay?: boolean };
export type Room = { name: string; subtitle: string; hint: string; spawn: Point; exit: Point; treasure: Point; platforms: Platform[]; hazard?: { x: number; y: number; range: number; period: number } };
export const ROOMS: Room[] = [
  { name: 'The first clearing', subtitle: 'A little courage goes a long way.', hint: 'That ledge is too high for a jump. Try the Feather.', spawn: {x:78,y:354}, exit:{x:879,y:260}, treasure:{x:596,y:158}, platforms:[
    {x:0,y:354,w:342,h:100},{x:258,y:318,w:84,h:36},{x:398,y:223,w:248,h:200},{x:732,y:260,w:228,h:180}] },
  { name: 'The broken crossing', subtitle: 'There is always another way across.', hint: 'Dash across the gap, or grow yourself a stepping stone.', spawn:{x:76,y:326}, exit:{x:881,y:326}, treasure:{x:435,y:252}, platforms:[
    {x:0,y:326,w:300,h:120},{x:560,y:326,w:400,h:120}] },
  { name: 'The lantern keeper', subtitle: 'Choose your moment. Make your own path.', hint: 'The red wisp is dangerous. Pause in the air to plan your way past.', spawn:{x:72,y:350}, exit:{x:880,y:300}, treasure:{x:405,y:151}, platforms:[
    {x:0,y:350,w:220,h:100},{x:252,y:310,w:64,h:160},{x:366,y:265,w:218,h:180},{x:748,y:300,w:212,h:150}] ,hazard:{x:668,y:278,range:64,period:4.2}},
];
export type Mode = 'ready' | 'playing' | 'planning' | 'complete';
export class World {
  roomIndex = 0; mode: Mode = 'ready'; selected: Card | null = null;
  cards: Record<Card, boolean> = {feather:true,step:true,briar:true};
  x=0; y=0; vx=0; vy=0; facing=1; grounded=false; coyote=0; bufferedJump=0; dash=0;
  time=0; elapsed=0; treasure=false; dark=false; transformations=true; attempts=1;
  briar: Platform | null=null; target: Point={x:0,y:0}; notice=''; effect=0; landingTransform=0; pendingTransform=false;
  events: string[]=[];
  get room() { return ROOMS[this.roomIndex]; }
  get platforms() { return this.briar ? [...this.room.platforms,this.briar] : this.room.platforms; }
  constructor(roomIndex=0) { this.reset(roomIndex); }
  reset(roomIndex=this.roomIndex) {
    this.roomIndex=roomIndex; this.x=this.room.spawn.x; this.y=this.room.spawn.y;
    this.vx=0; this.vy=0; this.facing=1; this.grounded=true; this.coyote=BALANCE.coyote;
    this.bufferedJump=0; this.dash=0; this.time=0; this.elapsed=0; this.treasure=false; this.dark=false;
    this.briar=null; this.selected=null; this.mode='playing'; this.effect=0; this.landingTransform=0; this.pendingTransform=false;
    this.cards={feather:true,step:true,briar:true}; this.notice=this.room.hint; this.events=[];
    this.target={x:this.x+100,y:this.y-36};
  }
  retry() { this.attempts++; this.reset(); }
  select(card:Card) {
    if(!this.cards[card] || this.mode==='complete' || this.mode==='ready') return false;
    this.mode='planning'; this.selected=card;
    this.target={x:Math.max(60,Math.min(900,this.x+this.facing*125)),y:Math.max(70,this.y-25)};
    this.events.push('select'); return true;
  }
  cancel() { if(this.mode==='planning') {this.mode='playing';this.selected=null;} }
  freeze() { if(this.mode==='playing') {this.mode='planning';this.selected=null;} }
  validBriar(target=this.target): {ok:boolean;reason:string} {
    const p={x:target.x-BALANCE.briarWidth/2,y:target.y,w:BALANCE.briarWidth,h:12};
    if(p.x<10||p.x+p.w>950||p.y<70||p.y>380) return {ok:false,reason:'Outside the clearing'};
    if(Math.hypot(target.x-this.x,target.y-(this.y-15))>BALANCE.briarReach) return {ok:false,reason:'Too far away'};
    if(this.platforms.some(a=>p.x<a.x+a.w&&p.x+p.w>a.x&&p.y<a.y+a.h&&p.y+p.h>a.y)) return {ok:false,reason:'Needs open space'};
    if(p.x<this.x+9&&p.x+p.w>this.x-9&&p.y<this.y&&p.y+p.h>this.y-30) return {ok:false,reason:'Too close to Red'};
    return {ok:true,reason:'Grow here'};
  }
  confirm() {
    const card=this.selected;
    if(this.mode!=='planning'||!card||!this.cards[card]) return false;
    if(card==='briar'&&!this.validBriar().ok) { this.notice=this.validBriar().reason;this.events.push('denied');return false; }
    this.cards[card]=false; this.mode='playing'; this.selected=null;
    if(card==='feather') {this.vy=-BALANCE.feather;this.grounded=false;this.coyote=0;this.dash=0;}
    if(card==='step') {this.dash=BALANCE.dashDuration;this.vx=this.facing*BALANCE.dashSpeed;this.vy=0;this.grounded=false;}
    if(card==='briar') this.briar={x:this.target.x-BALANCE.briarWidth/2,y:this.target.y,w:BALANCE.briarWidth,h:12,oneWay:true};
    if(this.transformations) {this.dark=!this.dark;this.pendingTransform=true;}
    this.effect=.6; this.events.push(card); this.notice=''; return true;
  }
  jump() { if(this.mode==='playing') this.bufferedJump=BALANCE.jumpBuffer; }
  hazardPosition() { const h=this.room.hazard;return h?{x:h.x+Math.sin(this.time/h.period*Math.PI*2)*h.range,y:h.y}:null; }
  step(dt:number, direction:number) {
    if(this.mode!=='playing') return;
    this.time+=dt;this.elapsed+=dt;this.effect=Math.max(0,this.effect-dt);this.landingTransform=Math.max(0,this.landingTransform-dt);
    this.bufferedJump=Math.max(0,this.bufferedJump-dt);this.coyote=this.grounded?BALANCE.coyote:Math.max(0,this.coyote-dt);
    if(this.bufferedJump>0&&this.coyote>0) {this.vy=-BALANCE.jump;this.grounded=false;this.coyote=0;this.bufferedJump=0;this.events.push('jump');}
    if(this.dash>0) {this.dash=Math.max(0,this.dash-dt);this.vx=this.facing*BALANCE.dashSpeed;this.vy=0;}
    else {this.vx=direction*BALANCE.speed;this.vy+=BALANCE.gravity*dt;if(direction)this.facing=direction;}
    let nx=this.x+this.vx*dt;
    for(const p of this.platforms) if(!p.oneWay && this.y>p.y+1&&this.y-30<p.y+p.h-1) {
      if(this.x+9<=p.x&&nx+9>p.x) {nx=p.x-9;this.dash=0;this.vx=0;}
      if(this.x-9>=p.x+p.w&&nx-9<p.x+p.w) {nx=p.x+p.w+9;this.dash=0;this.vx=0;}
    }
    this.x=Math.max(10,Math.min(950,nx));
    let ny=this.y+this.vy*dt;const wasGrounded=this.grounded;this.grounded=false;
    for(const p of this.platforms) if(this.x+8>p.x&&this.x-8<p.x+p.w) {
      if(this.vy>=0&&this.y<=p.y+.1&&ny>=p.y) {ny=p.y;this.vy=0;this.grounded=true;}
      else if(!p.oneWay&&this.vy<0&&this.y-30>=p.y+p.h&&ny-30<p.y+p.h) {ny=p.y+p.h+30;this.vy=0;}
    }
    this.y=ny;
    if(this.grounded&&!wasGrounded) this.events.push('land');
    if(this.grounded&&this.pendingTransform) {this.landingTransform=1.27;this.pendingTransform=false;}
    if(!this.treasure&&Math.hypot(this.x-this.room.treasure.x,this.y-18-this.room.treasure.y)<26) {this.treasure=true;this.events.push('treasure');}
    const h=this.hazardPosition();
    if(this.y>460||(h&&Math.abs(this.x-h.x)<19&&Math.abs(this.y-16-h.y)<25)) {
      this.retry();this.notice='Try another route. Your cards are back.';this.events.push('retry');return;
    }
    if(Math.abs(this.x-this.room.exit.x)<22&&Math.abs(this.y-this.room.exit.y)<12&&this.grounded) {this.mode='complete';this.events.push('complete');}
  }
}
