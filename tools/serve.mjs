// Dependency-free launcher for the prebuilt game. Serves only on this computer.
import http from 'node:http';
import {readFile,stat} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawn} from 'node:child_process';
const root=fileURLToPath(new URL('../dist/',import.meta.url));
const types={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.png':'image/png','.jpg':'image/jpeg','.svg':'image/svg+xml','.ogg':'audio/ogg','.wav':'audio/wav','.json':'application/json'};
const server=http.createServer(async(req,res)=>{
 if(req.method!=='GET'&&req.method!=='HEAD'){res.writeHead(405);res.end();return;}
 try{
  const pathname=decodeURIComponent(new URL(req.url,'http://localhost').pathname);
  const filename=path.resolve(root,'.'+(pathname==='/'?'/index.html':pathname));
  if(!filename.startsWith(root)){res.writeHead(403);res.end();return;}
  const info=await stat(filename);if(!info.isFile())throw Error('not a file');
  res.writeHead(200,{'Content-Type':types[path.extname(filename)]||'application/octet-stream','Cache-Control':'no-cache'});
  res.end(req.method==='HEAD'?undefined:await readFile(filename));
 }catch{res.writeHead(404);res.end('Not found');}
});
let port=Number(process.env.RED_PORT||4250);
server.on('error',e=>{if(e.code==='EADDRINUSE'&&port<4260){server.listen(++port,'127.0.0.1');}else{console.error(e.message);process.exit(1);}});
server.on('listening',()=>{
 const url=`http://127.0.0.1:${port}/`;console.log(`\nRED — The Other Side\n${url}\nLeave this window open. Ctrl+C stops the game server.\n`);
 if(process.argv.includes('--open')){
  const cmd=process.platform==='darwin'?'open':process.platform==='win32'?'cmd':'xdg-open';
  const args=process.platform==='win32'?['/c','start','',url]:[url];
  const child=spawn(cmd,args,{stdio:'ignore',detached:true});child.on('error',()=>console.log('Open the URL above in your browser.'));child.unref();
 }
});
server.listen(port,'127.0.0.1');
