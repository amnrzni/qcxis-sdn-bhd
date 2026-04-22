const http=require('http'),fs=require('fs'),path=require('path');
const root=path.join(__dirname,'Presentation');
http.createServer((q,r)=>{
  let p=path.join(root,q.url==='/'?'/index.html':q.url.split('?')[0]);
  fs.readFile(p,(e,d)=>{
    if(e){r.writeHead(404);return r.end('404');}
    const ext=path.extname(p);
    const ct={'.html':'text/html','.js':'text/javascript','.css':'text/css'}[ext]||'application/octet-stream';
    r.writeHead(200,{'Content-Type':ct});r.end(d);
  });
}).listen(8765,()=>console.log('listening 8765'));
