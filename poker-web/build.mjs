import {mkdir,cp,copyFile,rm} from 'node:fs/promises';
await rm(new URL('./dist',import.meta.url),{recursive:true,force:true});
await mkdir(new URL('./dist',import.meta.url),{recursive:true});
for(const name of ['index.html','style.css','game.mjs','model.mjs','enemies.mjs','art.mjs','environment.mjs','animation.mjs','journey.mjs','scenery.mjs','tiles.mjs','bridge.mjs'])await copyFile(new URL(name,import.meta.url),new URL('dist/'+name,import.meta.url));
await cp(new URL('./assets',import.meta.url),new URL('./dist/assets',import.meta.url),{recursive:true});
console.log('Built standalone poker game into dist/');
