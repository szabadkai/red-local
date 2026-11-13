// Deterministic QA player: normal movement and sword input, no health or damage overrides.
export function bossInput(w){
  const b=w.boss; if(!b)return {}; const dx=b.x-w.x,input={};
  if(b.state==='recover'){
   input.axis=Math.abs(dx)>45?Math.sign(dx):0;input.sword=Math.abs(dx)<75;
   if(Math.abs(dx)<75)input.axis=Math.sign(dx)*.1;
  }else if(b.state==='approach')input.axis=0;
  else if(b.state==='windup'){
   if((['chain','slam','cut','axe'].includes(b.pattern)||(['charge','bite'].includes(b.pattern)&&Math.abs(dx)<140))&&b.timer<.16&&w.grounded)input.jump=true;
   if(b.pattern==='silk'&&Math.abs(w.x-b.target)<90)input.axis=b.target<480?-1:1;
   if(b.pattern==='leap'&&Math.abs(w.x-b.target)<110)input.axis=b.target<480?1:-1;
  }else if(b.state==='strike'){
   if(['charge','bite'].includes(b.pattern)&&Math.abs(dx)<140&&w.grounded)input.jump=true;
   if(b.pattern==='leap'&&Math.abs(w.x-b.target)<110)input.axis=b.target<480?1:-1;
  }
  if(w.hazards.some(h=>h.kind==='ring'&&h.delay<=0&&Math.abs(h.x-w.x)<90)&&w.grounded)input.jump=true;
 return input;
}
