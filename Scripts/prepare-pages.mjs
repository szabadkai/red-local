import {access,cp,rm,writeFile} from 'node:fs/promises';

const root=new URL('../',import.meta.url);
const mainBuild=new URL('dist/',root);
const pokerBuild=new URL('poker-web/dist/',root);
const pokerDestination=new URL('poker/',mainBuild);

// Fail before changing the published folder if either build is missing.
await Promise.all([access(new URL('index.html',mainBuild)),access(new URL('index.html',pokerBuild))]);
await rm(pokerDestination,{recursive:true,force:true});
await cp(pokerBuild,pokerDestination,{recursive:true});
await writeFile(new URL('.nojekyll',mainBuild),'');
console.log('Pages artifact: original game at /, poker prototype at /poker/');
