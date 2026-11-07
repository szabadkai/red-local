import { World, type Card } from './model.ts';
export const ACTIONS=['left','right','jump','slot0','slot1','slot2','plan','retry'] as const;
export type Action=typeof ACTIONS[number];
export type Controls={keys:Record<Action,string>;slots:[Card,Card,Card]};
export const DEFAULT_KEYS:Record<Action,string>={left:'KeyA',right:'KeyD',jump:'Space',slot0:'KeyX',slot1:'KeyC',slot2:'KeyV',plan:'ShiftLeft',retry:'KeyR'};
export function defaults():Controls{return {keys:{...DEFAULT_KEYS},slots:['feather','step','briar']};}
export function keyLabel(code:string){return code.startsWith('Key')?code.slice(3):code.startsWith('Digit')?code.slice(5):({Space:'Space',ShiftLeft:'L Shift',ShiftRight:'R Shift',ArrowLeft:'←',ArrowRight:'→',ArrowUp:'↑',ArrowDown:'↓'} as Record<string,string>)[code]||code;}
export function remap(config:Controls,action:Action,code:string){
  if(!/^(Key[A-Z]|Digit[0-9]|Space|ShiftLeft|ShiftRight)$/.test(code))return false;
  const other=ACTIONS.find(a=>config.keys[a]===code);const old=config.keys[action];
  config.keys[action]=code;if(other&&other!==action)config.keys[other]=old;return true;
}
export function equip(config:Controls,index:number,card:Card){const other=config.slots.indexOf(card);const old=config.slots[index];config.slots[index]=card;if(other!==index)config.slots[other]=old;}
export function parseControls(raw:string|null):Controls{
  const c=defaults();if(!raw)return c;
  try{const saved=JSON.parse(raw);if(saved.version!==1)return c;
    if(ACTIONS.every(a=>typeof saved.keys?.[a]==='string'&&/^(Key[A-Z]|Digit[0-9]|Space|ShiftLeft|ShiftRight)$/.test(saved.keys[a]))&&new Set(ACTIONS.map(a=>saved.keys[a])).size===ACTIONS.length)c.keys={...saved.keys};
    if(Array.isArray(saved.slots)&&saved.slots.length===3&&new Set(saved.slots).size===3&&saved.slots.every((s:string)=>['feather','step','briar'].includes(s)))c.slots=[...saved.slots] as [Card,Card,Card];
  }catch{}return c;
}
export class DirectControls{
  held=new Set<string>();briarKey:string|null=null;planBlocked=false;
  world:World;config:Controls;
  constructor(world:World,config:Controls){this.world=world;this.config=config;}
  get direction(){return Number(this.held.has(this.config.keys.right)||this.held.has('ArrowRight'))-Number(this.held.has(this.config.keys.left)||this.held.has('ArrowLeft'));}
  activate(card:Card,heldKey:string|null=null){
    if(!this.world.select(card))return false;
    if(card==='briar'){
      this.briarKey=heldKey;
      for(const [dx,dy] of [[125,-25],[140,-50],[110,-60],[95,-80],[160,-80]]){
        const target={x:this.world.x+dx*this.world.facing,y:this.world.y+dy};
        if(this.world.validBriar(target).ok){this.world.target=target;break;}
      }
      return true;
    }
    this.briarKey=null;this.planBlocked=true;return this.world.confirm();
  }
  press(code:string){
    if(this.held.has(code))return;this.held.add(code);
    const k=this.config.keys;
    if(code===k.retry&&this.world.mode!=='ready'){this.clear();this.world.retry();return;}
    if(this.world.mode==='ready'||this.world.mode==='complete')return;
    if(code==='Escape'){this.cancel();return;}
    if(code===k.jump)this.world.jump();
    if(code===k.plan&&!this.planBlocked)this.world.freeze();
    const index=[k.slot0,k.slot1,k.slot2].indexOf(code);
    if(index!==-1)this.activate(this.config.slots[index],code);
  }
  release(code:string){
    this.held.delete(code);
    if(code===this.briarKey){this.briarKey=null;this.planBlocked=true;const valid=this.world.confirm();if(!valid)this.world.cancel();}
    if(code===this.config.keys.plan){if(!this.world.selected)this.world.cancel();this.planBlocked=false;}
    if(!this.held.has(this.config.keys.plan))this.planBlocked=false;
  }
  cancel(){this.briarKey=null;this.world.cancel();this.planBlocked=this.held.has(this.config.keys.plan);}
  clear(){this.held.clear();this.briarKey=null;this.planBlocked=false;}
}
