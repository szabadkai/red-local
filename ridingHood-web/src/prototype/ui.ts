import { World, ROOMS, type Card } from './model';
import './style.css';
import { CHAPTERS } from './rooms';
import { isRoomUnlocked, type Progress } from './progress';
import { ACTIONS, defaults, equip, remap, keyLabel, type Action, type Controls } from './controls';
export const CARD_INFO:Record<Card,{name:string;verb:string;desc:string}>={feather:{name:'The Feather',verb:'Rise above',desc:'Launch upward. Works in midair.'},step:{name:'The Step',verb:'Cross the impossible',desc:'Dash in the direction you face.'},briar:{name:'The Briar',verb:'Make your own way',desc:'Aim in open space. Grow a platform.'}};
export type UIActions={start:()=>void;resume:()=>void;select:(c:Card)=>void;retry:()=>void;next:()=>void;room:(i:number)=>void;mute:()=>void;help:(open:boolean)=>void;confirm:()=>void;cancel:()=>void;toggleForm:()=>void;settingsChange:()=>void;preferencesChange:()=>void};
export class UI {
  private journeyOpen=false; private hintLevel=0; private hintOpen=false; private lastHintRoom=-1; private prev=''; private helpOpen=false; private started=false; private binding:Action|null=null;
  constructor(private world:World,private actions:UIActions, private config:Controls, private progress:Progress) {
    document.body.innerHTML=`<div class="app"><header class="masthead"><a class="wordmark" href="./" aria-label="Red home">RED<span>THE OTHER SIDE</span></a><div class="edition"><span class="tiny-diamond">✦</span> A PLAYABLE FAIRY TALE</div><nav><button id="help" class="quiet">Controls & cards <span>⚙</span></button><button id="sound" class="icon-button" aria-label="Unmute sound" title="Sound">♫<i></i></button></nav></header>
+<main><section class="chapterbar"><div class="chapter-heading"><span class="eyebrow" id="chapter-index">CHAPTER I</span><h1 id="room-name">The first clearing</h1></div><button id="journey" class="quiet journey-button" aria-haspopup="dialog">Journey <span id="journey-count">0 / 12</span></button><button class="quiet retry" id="retry" title="Restart room (R)"><span>↻</span> Try again <kbd>R</kbd></button></section>
+<section class="game-frame"><div class="stage-wrap"><div id="game-container" aria-label="Platforming game. Move with A and D, jump with Space, use your equipped action buttons." tabindex="0"></div><div class="world-hud"><span id="form" class="form-tag"><i></i> LIGHT FORM</span><span id="treasure" class="treasure-tag">◇ <span>FOREST KEEPSAKE</span></span></div><div id="planning-tag" class="planning-tag" hidden><span>Ⅱ</span> TAKE A BREATH <small>Time is paused</small></div><div id="aim-label" class="aim-label" hidden></div><div class="stage-vignette"></div>
+<div id="intro" class="intro overlay"><div class="intro-copy"><span class="eyebrow">ONCE UPON ANOTHER TIME</span><h2>A small hood.<br>Three little miracles.</h2><p>Grandmother’s window has gone dark.<br>Carry a little light through the forest. Find your own way home.</p><div class="journey-actions"><button id="continue" class="primary" hidden>Continue journey <span>→</span></button><button id="begin" class="primary">Enter the forest <span>→</span></button></div><p id="journey-summary" class="journey-summary"></p><div class="intro-foot">THREE CHAPTERS · TWELVE LANTERNS · ONE WAY HOME</div></div></div>
+<div id="complete" class="overlay complete" hidden><div class="result"><span class="eyebrow">A PATH OF YOUR OWN</span><h2 id="result-title">Through the clearing.</h2><p id="result-copy"></p><div class="result-stats"><span id="result-cards"></span><span id="result-treasure"></span></div><button id="next" class="primary">Into the next clearing <span>→</span></button><button id="retry-result" class="quiet">Try a different route</button></div></div></div>
+<div class="hand-area"><div class="hand-caption"><span class="eyebrow">EQUIPPED CARDS</span><span id="hand-count">Three possibilities.</span><span class="hand-rule">One use each.<br>A fresh hand every try.</span></div><div class="cards">${(['feather','step','briar'] as Card[]).map((c,i)=>`<button class="card ${c}" data-card="${c}" aria-label="${i+1}: ${CARD_INFO[c].name}. ${CARD_INFO[c].desc}"><kbd>${i+1}</kbd><span class="card-art"><img src="assets/concept/${c}.png" alt="" draggable="false"></span><span class="card-copy"><span class="card-kicker">${CARD_INFO[c].verb}</span><strong>${CARD_INFO[c].name}</strong><span class="card-description">${CARD_INFO[c].desc}</span></span><span class="card-used">PLAYED</span><span class="card-corner">✧</span></button>`).join('')}</div><div class="hand-end"><span class="ornament">❧</span><span>Every path begins<br>with a choice.</span></div></div>
+<div class="context-bar"><span class="context-dot"></span><span id="context">Reach the lantern. Find your own way.</span><button id="hint" aria-haspopup="dialog">Need a hint?</button><button id="play-card" hidden>Play card <kbd>↵</kbd></button><button id="cancel-card" hidden>Cancel <kbd>Esc</kbd></button></div></section>
+<p id="save-status" class="save-status" role="status">Progress is saved in this browser. It does not sync across devices.</p><footer class="controls"><div id="controls-guide"><kbd>A</kbd><kbd>D</kbd><span>move</span><kbd>SPACE</kbd><span>jump</span><kbd>1</kbd><kbd>2</kbd><kbd>3</kbd><span>choose a card</span><kbd>SHIFT</kbd><span>pause & plan</span></div><span class="footer-note">A LITTLE EXPERIMENT IN FINDING YOUR WAY</span></footer></main>
+<dialog id="journey-dialog" aria-labelledby="journey-title"><button id="close-journey" class="close" aria-label="Close journey">×</button><span class="eyebrow">THE LIGHTS YOU CARRY</span><h2 id="journey-title">Your way home.</h2><p>Light a lantern to unlock the next clearing. Replay completed rooms for keepsakes and fewer cards.</p>${CHAPTERS.map((chapter,c)=>`<section class="journal-chapter"><h3>${c+1}. ${chapter.name}</h3><div class="journal-rooms">${ROOMS.map((room,i)=>room.chapter===c?`<button data-room="${i}" aria-label="Clearing ${i+1}: ${room.name}"><span>${String(i+1).padStart(2,'0')}</span><strong>${room.name}</strong><i></i></button>`:'').join('')}</div></section>`).join('')}<p class="fineprint">◆ Keepsake found · ✓ Lantern lit · Every replay starts with a fresh hand.</p></dialog><dialog id="hint-dialog" aria-labelledby="hint-title"><button id="close-hint" class="close" aria-label="Close hint">×</button><span class="eyebrow" id="hint-level"></span><h2 id="hint-title">A little guidance.</h2><p id="hint-copy"></p><div class="journey-actions"><button id="more-hint" class="quiet">Show a clearer hint</button><button id="hint-done" class="primary">Try this idea →</button></div></dialog><dialog id="help-dialog"><button id="close-help" class="close" aria-label="Close instructions">×</button><span class="eyebrow">A FEW THINGS TO KNOW</span><h2>Find your own way.</h2><p>Reach the glowing lantern in each clearing. The golden keepsake is an optional extra challenge.</p><p>Feather and Step fire immediately. Hold Briar to aim with the mouse or arrows, then release to grow a platform. Escape cancels. Pause is optional.</p><div id="binding-settings"></div><p id="binding-status" class="fineprint">Click a key to rebind it. Duplicate keys swap automatically.</p><div id="slot-settings"></div><button id="reset-controls" class="quiet">Restore default controls</button><section class="access-settings"><span class="eyebrow">MAKE YOURSELF AT HOME</span><label>Music <input id="music-volume" type="range" min="0" max="100" aria-label="Music volume"></label><label>Sound effects <input id="effects-volume" type="range" min="0" max="100" aria-label="Sound effects volume"></label><label><input id="reduced-motion" type="checkbox"> Reduce decorative motion</label><label><input id="assist" type="checkbox"> Gentle pace (70% speed, same puzzles)</label><label><input id="large-text" type="checkbox"> Larger interface text</label></section><p class="fineprint">Controller: left stick / D-pad move · A jump · X Feather · B Step · hold Y to aim Briar with either stick, release to place · LB pause · Back retry · Start settings. In menus: D-pad, A to choose, B to close.</p><label class="form-setting"><input id="form-toggle" type="checkbox" checked> Transform after playing a card</label><p class="fineprint">Your appearance changes; card powers stay the same in either form.</p><p class="fineprint">Art and audio belong to their respective creators. Purchased assets are not licensed for reuse. <a href="https://github.com/szabadkai/red-local/blob/main/ASSET_RIGHTS.md" target="_blank" rel="noopener">Asset rights</a> · <a href="https://github.com/szabadkai/red-local#credits" target="_blank" rel="noopener">Credits</a></p><button id="help-done" class="primary">Back to the forest <span>→</span></button></dialog></div>`.replace(/^\+/gm,'');
    const enter=(resume:boolean)=>{this.started=true;this.el('intro').hidden=true;resume?this.actions.resume():this.actions.start();this.update(true);this.el('game-container').focus();};
    for(const [id,field] of [['music-volume','musicVolume'],['effects-volume','effectsVolume']] as const){const input=this.el(id) as HTMLInputElement;input.value=String(this.progress[field]*100);input.oninput=()=>{this.progress[field]=Number(input.value)/100;this.actions.preferencesChange();};}
    for(const [id,field] of [['reduced-motion','reducedMotion'],['assist','assist'],['large-text','largeText']] as const){const input=this.el(id) as HTMLInputElement;input.checked=this.progress[field];input.onchange=()=>{this.progress[field]=input.checked;this.applyPreferences();this.actions.preferencesChange();};}
    this.applyPreferences();
    this.on('begin',()=>enter(false));this.on('continue',()=>enter(true));
    this.on('journey',()=>this.journey(true));this.on('close-journey',()=>this.journey(false));
    this.el('journey-dialog').addEventListener('cancel',e=>{e.preventDefault();this.journey(false);});
    this.on('hint',()=>this.hint(true));this.on('close-hint',()=>this.hint(false));this.on('hint-done',()=>this.hint(false));
    this.on('more-hint',()=>{this.hintLevel=Math.min(2,this.hintLevel+1);this.renderHint();if(this.hintLevel===2)this.el('hint-done').focus();});
    this.el('hint-dialog').addEventListener('cancel',e=>{e.preventDefault();this.hint(false);});
    this.on('retry',()=>this.actions.retry());this.on('retry-result',()=>this.actions.retry());this.on('next',()=>this.actions.next());
    this.on('play-card',()=>this.actions.confirm());this.on('cancel-card',()=>this.actions.cancel());
    this.on('sound',()=>this.actions.mute());
    this.on('reset-controls',()=>{const d=defaults();this.config.keys=d.keys;this.config.slots=d.slots;this.actions.settingsChange();this.renderSettings();this.update(true);});
    this.on('help',()=>this.help(true));this.on('close-help',()=>this.help(false));this.on('help-done',()=>this.help(false));
    this.el('help-dialog').addEventListener('cancel',e=>{e.preventDefault();this.help(false);});
    this.el('form-toggle').addEventListener('change',()=>this.actions.toggleForm());
    document.querySelectorAll<HTMLButtonElement>('[data-card]').forEach(e=>e.onclick=()=>{this.actions.select(e.dataset.card as Card);e.blur();});
    document.querySelectorAll<HTMLButtonElement>('[data-room]').forEach(e=>e.onclick=()=>{if(this.journeyOpen)this.journey(false);this.started=true;this.el('intro').hidden=true;this.actions.room(Number(e.dataset.room));e.blur();});
    this.renderSettings();this.update(true);
  }
  applyPreferences(){document.body.classList.toggle('reduce-motion',this.progress.reducedMotion);document.body.classList.toggle('large-text',this.progress.largeText);}
  dismissModal(){if(this.helpOpen)this.help(false);else if(this.hintOpen)this.hint(false);else if(this.journeyOpen)this.journey(false);}
  menuAdjust(direction:number){
    const active=document.activeElement;
    if(active instanceof HTMLInputElement&&active.type==='range'){
      active.value=String(Math.max(0,Math.min(100,Number(active.value)+direction*5)));active.dispatchEvent(new Event('input',{bubbles:true}));
    }else if(active instanceof HTMLSelectElement){
      active.selectedIndex=(active.selectedIndex+direction+active.options.length)%active.options.length;active.dispatchEvent(new Event('change',{bubbles:true}));
    }else this.menuStep(direction);
  }
  menuStep(direction:number){
    const root=document.querySelector('dialog[open]')??(this.world.mode==='ready'?this.el('intro'):this.world.mode==='complete'?this.el('complete'):null);
    if(!root)return;
    const items=[...root.querySelectorAll<HTMLElement>('button:not(:disabled),input,select,a')].filter(el=>el.getClientRects().length>0);
    const index=items.indexOf(document.activeElement as HTMLElement);items[(index+direction+items.length)%items.length]?.focus();
  }
  el(id:string){return document.getElementById(id)!;}
  on(id:string,fn:()=>void){this.el(id).addEventListener('click',fn);}
  help(open:boolean){this.binding=null;this.helpOpen=open;if(open)this.renderSettings();const dialog=this.el('help-dialog') as HTMLDialogElement;open?dialog.showModal():dialog.close();this.actions.help(open);if(!open)this.el('game-container').focus();}
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
  journey(open:boolean){
    this.journeyOpen=open;
    const dialog=this.el('journey-dialog') as HTMLDialogElement;
    open?dialog.showModal():dialog.close();this.actions.help(open);
    if(!open)this.el('game-container').focus();
  }
  hint(open:boolean){
    this.hintOpen=open;
    const dialog=this.el('hint-dialog') as HTMLDialogElement;
    if(open){if(this.lastHintRoom!==this.world.roomIndex){this.hintLevel=0;this.lastHintRoom=this.world.roomIndex;}this.renderHint();dialog.showModal();}
    else dialog.close();
    this.actions.help(open);
    if(!open)this.el('game-container').focus();
  }
  renderHint(){
    this.el('hint-level').textContent=['NOTICE THE PATH','CONSIDER YOUR CARDS','A ROUTE TO TRY'][this.hintLevel];
    this.el('hint-copy').textContent=this.world.room.hints[this.hintLevel];
    this.el('more-hint').hidden=this.hintLevel===2;
  }
  setSaveStatus(saved:boolean){this.el('save-status').textContent=saved?'Progress saved in this browser · no cross-device sync.':'Saving is unavailable in this browser. You can still play; progress will be lost when you close the page.';}
  get isHelpOpen(){return this.helpOpen||this.hintOpen||this.journeyOpen;}
  tutorial(){
    const w=this.world;
    if(w.roomIndex!==0)return '';
    const key=(card:Card)=>keyLabel(this.config.keys[('slot'+this.config.slots.indexOf(card)) as Action]);
    if(w.x<205&&w.cards.feather)return `Move with ${keyLabel(this.config.keys.left)} / ${keyLabel(this.config.keys.right)}. Press ${keyLabel(this.config.keys.jump)} to jump onto the short stone step.`;
    if(w.x<398&&w.cards.feather)return `From the short step, press ${key('feather')} to rise with Feather. Keep moving right toward the high island.`;
    if(w.x>=398&&w.x<645)return `The golden keepsake is optional. Jump from the island’s far edge toward the lantern. ${keyLabel(this.config.keys.plan)} pauses time whenever you need to think.`;
    if(w.x>=645)return 'Reach the lantern to light the way. Every new clearing restores all three cards.';
    return `Your cards return when you retry (${keyLabel(this.config.keys.retry)}). Try using Feather from the short step.`;
  }
  setMuted(muted:boolean){this.el('sound').classList.toggle('muted',muted);this.el('sound').setAttribute('aria-label',muted?'Unmute sound':'Mute sound');}
  update(force=false){
    const w=this.world;const sig=JSON.stringify([w.mode,w.selected,w.cards,w.dark,w.treasure,w.roomIndex,w.notice,w.attempts,this.config,this.started,this.progress,this.tutorial(),w.selected==='briar'?w.validBriar():null]);
    if(sig===this.prev&&!force)return;this.prev=sig;
    this.el('journey-count').textContent=`${this.progress.completed.length} / ${ROOMS.length}`;
    this.el('continue').hidden=!this.progress.started;
    this.el('begin').textContent=this.progress.started?'Revisit the first clearing':'Enter the forest →';
    this.el('journey-summary').textContent=this.progress.started?`${this.progress.completed.length} / ${ROOMS.length} lanterns lit · ${this.progress.keepsakes.length} ${this.progress.keepsakes.length===1?'keepsake':'keepsakes'} found. Continue begins with a fresh hand.`:'Three cards. One use each. A fresh hand whenever you retry.';
    this.el('form-toggle').toggleAttribute('checked',w.transformations);
    (this.el('form-toggle') as HTMLInputElement).checked=w.transformations;
    this.el('hint').hidden=!this.started||w.mode==='complete';
    this.el('retry').toggleAttribute('disabled',!this.started);
    this.el('room-name').textContent=w.room.name;this.el('chapter-index').textContent=`${CHAPTERS[w.room.chapter].name.toUpperCase()} · ${w.roomIndex+1} / ${ROOMS.length}`;
    document.querySelectorAll<HTMLButtonElement>('[data-room]').forEach(e=>{e.disabled=!isRoomUnlocked(this.progress,Number(e.dataset.room));e.classList.toggle('active',Number(e.dataset.room)===w.roomIndex);e.setAttribute('aria-current',Number(e.dataset.room)===w.roomIndex?'step':'false');const room=ROOMS[Number(e.dataset.room)];e.classList.toggle('cleared',this.progress.completed.includes(room.id));e.querySelector('i')!.textContent=e.disabled?'Locked — light the previous lantern':(this.progress.keepsakes.includes(room.id)?'◆ ':this.progress.completed.includes(room.id)?'✓ ':'')+(this.progress.bestCards[room.id]!==undefined?`${this.progress.bestCards[room.id]} cards`:'');});
    this.el('form').innerHTML=`<i></i> ${w.dark?'DARK':'LIGHT'} FORM`;this.el('form').classList.toggle('dark',w.dark);
    this.el('treasure').innerHTML=`${w.treasure?'◆':'◇'} <span>${w.treasure?'KEEPSAKE FOUND':'FOREST KEEPSAKE'}</span>`;this.el('treasure').classList.toggle('found',w.treasure);
    const left=Object.values(w.cards).filter(Boolean).length;
    this.el('hand-count').textContent=left===3?'Three possibilities.':`${left} ${left===1?'possibility':'possibilities'} left.`;
    document.querySelectorAll<HTMLButtonElement>('[data-card]').forEach(e=>{const c=e.dataset.card as Card;const slot=this.config.slots.indexOf(c);const label=keyLabel(this.config.keys[('slot'+slot) as Action]);e.style.order=String(slot);e.querySelector('kbd')!.textContent=label;e.setAttribute('aria-label',`${label}: ${CARD_INFO[c].name}. ${c==='briar'?'Hold to aim; release to place.':'Press to use.'}`);e.disabled=!w.cards[c]||!this.started||w.mode==='complete';e.classList.toggle('spent',!w.cards[c]);e.classList.toggle('selected',w.selected===c);e.setAttribute('aria-pressed',String(w.selected===c));});
    this.el('controls-guide').innerHTML=`<kbd>${keyLabel(this.config.keys.left)}</kbd><kbd>${keyLabel(this.config.keys.right)}</kbd><span>move</span><kbd>${keyLabel(this.config.keys.jump)}</kbd><span>jump</span>${this.config.slots.map((c,i)=>`<kbd>${keyLabel(this.config.keys[('slot'+i) as Action])}</kbd><span>${c==='briar'?'hold / release':c}</span>`).join('')}`;
    this.el('retry').querySelector('kbd')!.textContent=keyLabel(this.config.keys.retry);
    this.el('planning-tag').hidden=w.mode!=='planning';
    this.el('play-card').hidden=!w.selected;this.el('cancel-card').hidden=w.mode!=='planning';
    let hint=(w.notice.startsWith('Paused')||w.notice.startsWith('Try another')?w.notice:this.tutorial())||w.notice||'Reach the lantern. The keepsake is yours if you can find a way.';
    if(w.mode==='planning')hint=w.selected?`${CARD_INFO[w.selected].name} — ${w.selected==='briar'?w.validBriar().reason+'. Mouse or arrows to aim.':CARD_INFO[w.selected].desc} Release the assigned button to place. Escape cancels.`:'Time is yours. Use an equipped action, or release pause to keep moving.';
    this.el('context').textContent=hint;
    const justCompleted=this.el('complete').hidden&&w.mode==='complete';
    this.el('complete').hidden=w.mode!=='complete';
    if(w.mode==='complete'){
      this.el('result-title').textContent=w.roomIndex===ROOMS.length-1?'Welcome home, Red.':(ROOMS[w.roomIndex+1]?.chapter!==w.room.chapter?'A chapter, carried with you.':'A lantern, lit.');
      this.el('result-copy').textContent=w.room.memory+(w.roomIndex===ROOMS.length-1&&this.progress.keepsakes.length===ROOMS.length?' In your basket, every keepsake has a story. Together, you remember them all.':'');
      this.el('result-cards').textContent=`${3-left} of 3 cards played · best ${this.progress.bestCards[w.room.id]??3-left}`;
      this.el('result-treasure').textContent=w.treasure?'◆ Keepsake found':'◇ Keepsake left behind';
      if(justCompleted)this.el('next').focus();
      this.el('next').innerHTML=w.roomIndex===ROOMS.length-1?'Walk the forest again <span>↻</span>':`${ROOMS[w.roomIndex+1]?.chapter!==w.room.chapter?'Enter '+CHAPTERS[ROOMS[w.roomIndex+1].chapter].name:'Into the next clearing'} <span>→</span>`;
    }
  }
}
