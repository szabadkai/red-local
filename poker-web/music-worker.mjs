import './chip.mjs';
// {name} renders assets/music/<name>.mml; {name,text} renders the given song text (sound effects).
onmessage=async({data:{name,text}})=>{
 try{
  if(!text){
   const res=await fetch(new URL(`./assets/music/${name}.mml`,import.meta.url));
   if(!res.ok)throw new Error(`${res.status} loading ${name}.mml`);
   text=await res.text();
  }
  const {samples,song}=globalThis.Chip.render(text);
  postMessage({name,samples,rate:globalThis.Chip.SR,tempo:song.tempo},[samples.buffer]);
 }catch(error){postMessage({name,error:String(error)});}
};
