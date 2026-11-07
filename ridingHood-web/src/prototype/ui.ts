import { World, ROOMS, type Card } from './model';
import './style.css';
import { ACTIONS, defaults, equip, remap, keyLabel, type Action, type Controls } from './controls';
export const CARD_INFO:Record<Card,{name:string;verb:string;desc:string}>={feather:{name:'The Feather',verb:'Rise above',desc:'Launch upward. Works in midair.'},step:{name:'The Step',verb:'Cross the impossible',desc:'Dash in the direction you face.'},briar:{name:'The Briar',verb:'Make your own way',desc:'Aim in open space. Grow a platform.'}};
export type UIActions={start:()=>void;select:(c:Card)=>void;retry:()=>void;next:()=>void;room:(i:number)=>void;mute:()=>void;help:(open:boolean)=>void;confirm:()=>void;cancel:()=>void;toggleForm:()=>void;settingsChange:()=>void};
export class UI {
  private prev=''; private helpOpen=false; private started=false; private binding:Action|null=null;
  constructor(private world:World,private actions:UIActions, private config:Controls) {
    document.body.innerHTML=`<div class="app"><header class="masthead"><a class="wordmark" href="./" aria-label="Red home">RED<span>THE OTHER SIDE</span></a><div class="edition"><span class="tiny-diamond">✦</span> A PLAYABLE FAIRY TALE</div><nav><button id="help" class="quiet">Controls & cards <span>⚙</span></button><button id="sound" class="icon-button" aria-label="Unmute sound" title="Sound">♫<i></i></button></nav></header>
+<main><section class="chapterbar"><div class="chapter-heading"><span class="eyebrow" id="chapter-index">CHAPTER I</span><h1 id="room-name">The first clearing</h1></div><div class="chapters" aria-label="Choose chapter">${ROOMS.map((r,i)=>`<button data-room="${i}" aria-label="Chapter ${i+1}: ${r.name}" title="${r.name}"><span>0${i+1}</span><i></i></button>`).join('')}</div><button class="quiet retry" id="retry" title="Restart room (R)"><span>↻</span> Try again <kbd>R</kbd></button></section>
+<section class="game-frame"><div class="stage-wrap"><div id="game-container" aria-label="Platforming game. Move with A and D, jump with Space, use your equipped action buttons." tabindex="0"></div><div class="world-hud"><span id="form" class="form-tag"><i></i> LIGHT FORM</span><span id="treasure" class="treasure-tag">◇ <span>FOREST KEEPSAKE</span></span></div><div id="planning-tag" class="planning-tag" hidden><span>Ⅱ</span> TAKE A BREATH <small>Time is paused</small></div><div id="aim-label" class="aim-label" hidden></div><div class="stage-vignette"></div>
+<div id="intro" class="intro overlay"><div class="intro-copy"><span class="eyebrow">ONCE UPON ANOTHER TIME</span><h2>A small hood.<br>Three little miracles.</h2><p>The path is broken. Your hand holds a way through.<br>Run, jump, and use your equipped magic without missing a beat.</p><button id="begin" class="primary">Enter the forest <span>→</span></button><div class="intro-foot">THREE CLEARINGS · NO RUSH · TRY ANOTHER WAY</div></div></div>
+<div id="complete" class="overlay complete" hidden><div class="result"><span class="eyebrow">A PATH OF YOUR OWN</span><h2 id="result-title">Through the clearing.</h2><p id="result-copy"></p><div class="result-stats"><span id="result-cards"></span><span id="result-treasure"></span></div><button id="next" class="primary">Into the next clearing <span>→</span></button><button id="retry-result" class="quiet">Try a different route</button></div></div></div>
+<div class="hand-area"><div class="hand-caption"><span class="eyebrow">EQUIPPED CARDS</span><span id="hand-count">Three possibilities.</span><span class="hand-rule">One use each.<br>A fresh hand every try.</span></div><div class="cards">${(['feather','step','briar'] as Card[]).map((c,i)=>`<button class="card ${c}" data-card="${c}" aria-label="${i+1}: ${CARD_INFO[c].name}. ${CARD_INFO[c].desc}"><kbd>${i+1}</kbd><span class="card-art"><img src="assets/concept/${c}.png" alt="" draggable="false"></span><span class="card-copy"><span class="card-kicker">${CARD_INFO[c].verb}</span><strong>${CARD_INFO[c].name}</strong><span class="card-description">${CARD_INFO[c].desc}</span></span><span class="card-used">PLAYED</span><span class="card-corner">✧</span></button>`).join('')}</div><div class="hand-end"><span class="ornament">❧</span><span>Every path begins<br>with a choice.</span></div></div>
+<div class="context-bar"><span class="context-dot"></span><span id="context">Reach the lantern. Find your own way.</span><button id="play-card" hidden>Play card <kbd>↵</kbd></button><button id="cancel-card" hidden>Cancel <kbd>Esc</kbd></button></div></section>
+<footer class="controls"><div id="controls-guide"><kbd>A</kbd><kbd>D</kbd><span>move</span><kbd>SPACE</kbd><span>jump</span><kbd>1</kbd><kbd>2</kbd><kbd>3</kbd><span>choose a card</span><kbd>SHIFT</kbd><span>pause & plan</span></div><span class="footer-note">A LITTLE EXPERIMENT IN FINDING YOUR WAY</span></footer></main>
+<dialog id="help-dialog"><button id="close-help" class="close" aria-label="Close instructions">×</button><span class="eyebrow">A FEW THINGS TO KNOW</span><h2>Find your own way.</h2><p>Reach the glowing lantern in each clearing. The golden keepsake is an optional extra challenge.</p><p>Feather and Step fire immediately. Hold Briar to aim with the mouse or arrows, then release to grow a platform. Escape cancels. Pause is optional.</p><div id="binding-settings"></div><p id="binding-status" class="fineprint">Click a key to rebind it. Duplicate keys swap automatically.</p><div id="slot-settings"></div><button id="reset-controls" class="quiet">Restore default controls</button><label class="form-setting"><input id="form-toggle" type="checkbox" checked> Transform after playing a card</label><p class="fineprint">Your appearance changes; card powers stay the same in this prototype.</p><button id="help-done" class="primary">Back to the forest <span>→</span></button></dialog></div>`.replace(/^\+/gm,'');
    this.on('begin',()=>{this.started=true;this.el('intro').hidden=true;this.actions.start();this.update(true);});
    this.on('retry',()=>this.actions.retry());this.on('retry-result',()=>this.actions.retry());this.on('next',()=>this.actions.next());
    this.on('play-card',()=>this.actions.confirm());this.on('cancel-card',()=>this.actions.cancel());
    this.on('sound',()=>this.actions.mute());
    this.on('reset-controls',()=>{const d=defaults();this.config.keys=d.keys;this.config.slots=d.slots;this.actions.settingsChange();this.renderSettings();this.update(true);});
    this.on('help',()=>this.help(true));this.on('close-help',()=>this.help(false));this.on('help-done',()=>this.help(false));
    this.el('help-dialog').addEventListener('cancel',e=>{e.preventDefault();this.help(false);});
    this.el('form-toggle').addEventListener('change',()=>this.actions.toggleForm());
    document.querySelectorAll<HTMLButtonElement>('[data-card]').forEach(e=>e.onclick=()=>{this.actions.select(e.dataset.card as Card);e.blur();});
    document.querySelectorAll<HTMLButtonElement>('[data-room]').forEach(e=>e.onclick=()=>{this.started=true;this.el('intro').hidden=true;this.actions.room(Number(e.dataset.room));e.blur();});
    this.renderSettings();this.update(true);
  }
  el(id:string){return document.getElementById(id)!;}
  on(id:string,fn:()=>void){this.el(id).addEventListener('click',()=>{fn();(document.activeElement as HTMLElement)?.blur();});}
  help(open:boolean){this.binding=null;this.helpOpen=open;if(open)this.renderSettings();const dialog=this.el('help-dialog') as HTMLDialogElement;open?dialog.showModal():dialog.close();this.actions.help(open);}
  renderSettings(){
    const names:Record<Action,string>={left:'Move left',right:'Move right',jump:'Jump',slot0:'Action slot 1',slot1:'Action slot 2',slot2:'Action slot 3',plan:'Pause / plan',retry:'Restart'};
    this.el('binding-settings').innerHTML=ACTIONS.map(a=>`<div class="binding-row"><span>${names[a]}</span><button data-bind="${a}" class="key-bind">${this.binding===a?'Press a key…':keyLabel(this.config.keys[a])}</button></div>`).join('');
    document.querySelectorAll<HTMLButtonElement>('[data-bind]').forEach(el=>el.onclick=()=>{this.binding=el.dataset.bind as Action;this.renderSettings();this.el('binding-status').textContent='Press a letter, number, Space or Shift. Escape cancels.';});
    this.el('slot-settings').innerHTML='<span class="eyebrow">ASSIGN YOUR CARDS</span>'+this.config.slots.map((c,i)=>`<label class="slot-row">Slot ${i+1} · ${keyLabel(this.config.keys[('slot'+i) as Action])}<select data-slot="${i}" aria-label="Card in slot ${i+1}">${(['feather','step','briar'] as Card[]).map(v=>`<option value="${v}" ${c===v?'selected':''}>${CARD_INFO[v].name}</option>`).join('')}</select></label>`).join('');
    document.querySelectorAll<HTMLSelectElement>('[data-slot]').forEach(el=>el.onchange=()=>{equip(this.config,Number(el.dataset.slot),el.value as Card);this.actions.settingsChange();this.renderSettings();this.update(true);});
  }
  handleBindingKey(e:KeyboardEvent){
    if(!this.binding)return false;e.preventDefault();
    if(e.code==='Escape'){this.binding=null;this.renderSettings();return true;}
    if(remap(this.config,this.binding,e.code)){this.binding=null;this.actions.settingsChange();this.renderSettings();this.el('binding-status').textContent='Saved on this device.';this.update(true);}
    else this.el('binding-status').textContent='Use a letter, number, Space or Shift. Escape cancels.';
    return true;
  }
  get isHelpOpen(){return this.helpOpen;}
  setMuted(muted:boolean){this.el('sound').classList.toggle('muted',muted);this.el('sound').setAttribute('aria-label',muted?'Unmute sound':'Mute sound');}
  update(force=false){
    const w=this.world;const sig=JSON.stringify([w.mode,w.selected,w.cards,w.dark,w.treasure,w.roomIndex,w.notice,w.attempts,this.config,this.started,w.selected==='briar'?w.validBriar():null]);
    if(sig===this.prev&&!force)return;this.prev=sig;
    this.el('room-name').textContent=w.room.name;this.el('chapter-index').textContent=`CHAPTER ${['I','II','III'][w.roomIndex]}`;
    document.querySelectorAll<HTMLElement>('[data-room]').forEach(e=>{e.classList.toggle('active',Number(e.dataset.room)===w.roomIndex);e.setAttribute('aria-current',Number(e.dataset.room)===w.roomIndex?'step':'false');});
    this.el('form').innerHTML=`<i></i> ${w.dark?'DARK':'LIGHT'} FORM`;this.el('form').classList.toggle('dark',w.dark);
    this.el('treasure').innerHTML=`${w.treasure?'◆':'◇'} <span>${w.treasure?'KEEPSAKE FOUND':'FOREST KEEPSAKE'}</span>`;this.el('treasure').classList.toggle('found',w.treasure);
    const left=Object.values(w.cards).filter(Boolean).length;
    this.el('hand-count').textContent=left===3?'Three possibilities.':`${left} ${left===1?'possibility':'possibilities'} left.`;
    document.querySelectorAll<HTMLButtonElement>('[data-card]').forEach(e=>{const c=e.dataset.card as Card;const slot=this.config.slots.indexOf(c);const label=keyLabel(this.config.keys[('slot'+slot) as Action]);e.style.order=String(slot);e.querySelector('kbd')!.textContent=label;e.setAttribute('aria-label',`${label}: ${CARD_INFO[c].name}. ${c==='briar'?'Hold to aim; release to place.':'Press to use.'}`);e.disabled=!w.cards[c]||!this.started||w.mode==='complete';e.classList.toggle('spent',!w.cards[c]);e.classList.toggle('selected',w.selected===c);e.setAttribute('aria-pressed',String(w.selected===c));});
    this.el('controls-guide').innerHTML=`<kbd>${keyLabel(this.config.keys.left)}</kbd><kbd>${keyLabel(this.config.keys.right)}</kbd><span>move</span><kbd>${keyLabel(this.config.keys.jump)}</kbd><span>jump</span>${this.config.slots.map((c,i)=>`<kbd>${keyLabel(this.config.keys[('slot'+i) as Action])}</kbd><span>${c==='briar'?'hold / release':c}</span>`).join('')}`;
    this.el('retry').querySelector('kbd')!.textContent=keyLabel(this.config.keys.retry);
    this.el('planning-tag').hidden=w.mode!=='planning';
    this.el('play-card').hidden=!w.selected;this.el('cancel-card').hidden=w.mode!=='planning';
    let hint=w.notice||'Reach the lantern. The keepsake is yours if you can find a way.';
    if(w.mode==='planning')hint=w.selected?`${CARD_INFO[w.selected].name} — ${w.selected==='briar'?w.validBriar().reason+'. Mouse or arrows to aim.':CARD_INFO[w.selected].desc} Release the assigned button to place. Escape cancels.`:'Time is yours. Use an equipped action, or release pause to keep moving.';
    this.el('context').textContent=hint;
    this.el('complete').hidden=w.mode!=='complete';
    if(w.mode==='complete'){
      this.el('result-title').textContent=w.roomIndex===2?'Your own kind of magic.':'Through the clearing.';
      this.el('result-copy').textContent=w.roomIndex===2?'Three clearings, and a path that belongs to you.':'There was more than one way. You found yours.';
      this.el('result-cards').textContent=`${3-left} of 3 cards played`;
      this.el('result-treasure').textContent=w.treasure?'◆ Keepsake found':'◇ Keepsake left behind';
      this.el('next').innerHTML=w.roomIndex===2?'Walk the forest again <span>↻</span>':'Into the next clearing <span>→</span>';
    }
  }
}
