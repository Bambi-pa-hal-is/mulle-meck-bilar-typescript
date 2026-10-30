import assert from 'node:assert/strict';
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE ? pathToFileURL(process.env.PLAYWRIGHT_MODULE).href : 'playwright');
const browser = await chromium.launch({headless:true,...(process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE ? {executablePath:process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE} : {})});
fs.mkdirSync('docs',{recursive:true});
const page=await browser.newPage({viewport:{width:1100,height:850}});
const errors=[];
page.on('pageerror',e=>errors.push(e.message));
const base=process.env.QA_BASE_URL ?? 'http://localhost:5173';
try {
  await page.goto(`${base}/?movie=05&user=ArtworkQA`);
  await page.locator('#startText').filter({hasText:'Klicka'}).waitFor({timeout:90000});
  assert.equal(await page.locator('#customCarAssetsBox').isChecked(),false);
  await page.locator('#customCarAssetsBox').check();
  assert.equal(await page.locator('#start').isVisible(),true);
  await page.reload();
  await page.locator('#startText').filter({hasText:'Klicka'}).waitFor({timeout:90000});
  assert.equal(await page.locator('#customCarAssetsBox').isChecked(),true);
  await page.locator('#startText').click();
  await page.waitForFunction(()=>window.G?.dir?.mode==='Showing' || window.G?.dir?.mode==='Driving');
  await page.evaluate(()=>{window.makeCar('Good');window.G.dir.send('ShowOff','fakeMouse');});
  await page.waitForFunction(()=>window.G?.dir?.mode==='Driving');
  await page.waitForFunction(()=>window.G.dir.display.sprite.member.info.name==='AssembledOverworldCar');
  const coverage=await page.evaluate(async()=>{
    const manifest=await fetch('/assets/overworld-parts/manifest.json').then(r=>r.json());
    // Include the optional scrapyard parts in the coverage audit.
    await window.G.mulle.load(true);
    const views=new Set(manifest.map(p=>p.view.toLowerCase()));
    const missing=[];
    for(const p of window.G.mulle.parts.parts.values()){
      const large=p.id===1||(Array.isArray(p.requires)&&p.requires.some(s=>/^b[124]$|^a(1|13|11|3|18)$/.test(s.name)));
      if(large&&p.useView&&!p.prop('EngineType')&&!views.has(p.useView.toLowerCase()))missing.push(p.id);
    }
    return {designs:manifest.length,missing};
  });
  assert.equal(coverage.designs,107);
  assert.deepEqual(coverage.missing,[]);
  const initial=await page.evaluate(()=>({mode:window.G.dir.mode,parts:window.G.mulle.user.car.parts,member:window.G.dir.display.sprite.member.info.name}));
  assert.equal(initial.member,'AssembledOverworldCar');
  await page.locator('#stage').screenshot({path:'docs/overworld-driving-preview.png'});
  const result=await page.evaluate(async()=>{
    const {OverworldCar}=await import('/src/game/overworldcar.ts');
    const {Car}=await import('/src/game/car.ts');
    const {G,engine}=window,db=G.mulle.parts,m=engine.movie;
    const car=new Car(db);car.addPart(1);
    const renderer=new OverworldCar(m,car,db),s=m.sprite(120);
    const wait=async()=>{for(let i=0;i<200;i++){if(renderer.display(s,16,0))return;await new Promise(r=>setTimeout(r,25));}throw Error('Artwork timeout');};
    await wait();
    const frames=new Set();
    for(let d=1;d<=16;d++)for(let slope=-2;slope<=2;slope++){
      renderer.display(s,d,slope);
      const image=s.image.img;
      const pixels=image.getContext('2d').getImageData(0,0,80,80).data;
      // Car artwork must fit within its canvas at every heading/slope.
      for(let y=0;y<80;y++)for(let x=0;x<80;x++)if((x===0||y===0||x===79||y===79)&&pixels[(y*80+x)*4+3])throw Error('Clipped car frame');
      frames.add(image.toDataURL());
    }
    renderer.display(s,16,0);const bare=s.image.img.toDataURL();
    car.addPart(25);car.addPart(29);car.addPart(28);car.addPart(142);car.addPart(145);
    await wait();const red=s.image.img.toDataURL();
    car.removePart(25);car.removePart(29);car.removePart(28);car.addPart(300);car.addPart(302);car.addPart(301);
    await wait();const green=s.image.img.toDataURL();
    // The same wooden crate artwork can mount at either end of the car.
    // Verify the rendered change moves across the car, rather than checking internal layer data.
    const probeCar=new Car(db);probeCar.addPart(1);
    const probe=new OverworldCar(m,probeCar,db);
    const probeWait=async()=>{for(let i=0;i<200;i++){if(probe.display(s,16,0))return;await new Promise(resolve=>setTimeout(resolve,25));}throw Error('Morph artwork timeout');};
    await probeWait();const baseline=s.image.img.getContext('2d').getImageData(0,0,80,80).data;
    const differenceCenter=()=>{
      const data=s.image.img.getContext('2d').getImageData(0,0,80,80).data;
      let weight=0,weightedY=0;
      for(let p=0;p<80*80;p++){
        let delta=0;for(let c=0;c<4;c++)delta+=Math.abs(data[p*4+c]-baseline[p*4+c]);
        weight+=delta;weightedY+=Math.floor(p/80)*delta;
      }
      return weightedY/weight;
    };
    probeCar.addPart(15);await probeWait();const frontCrate=differenceCenter();
    probeCar.removePart(15);probeCar.addPart(16);await probeWait();const rearCrate=differenceCenter();
    probe.dispose();
    const gallery=document.createElement('canvas');gallery.width=1000;gallery.height=320;
    const g=gallery.getContext('2d');g.fillStyle='#e4dfce';g.fillRect(0,0,1000,320);
    const samples=[[1,25,29,28,142,145],[1,300,302,301,246,247],[1,174,177,175,142,145],[1,168,264,173,149],[1,604,607,606,246,247]];
    const labels=['Red racer','Green racer','Ambulance','Scrapyard special','Plugin shark'];
    for(let i=0;i<samples.length;i++){
      g.fillStyle='#3b3934';g.font='bold 16px sans-serif';g.textAlign='center';g.fillText(labels[i],i*200+100,28);
      const c=new Car(db);for(const id of samples[i])c.addPart(id);
      const r=new OverworldCar(m,c,db);
      for(let t=0;t<200;t++){if(r.display(s,16,0))break;await new Promise(resolve=>setTimeout(resolve,25));}
      for(let heading=1;heading<=16;heading++)for(let slope=-2;slope<=2;slope++){
        r.display(s,heading,slope);
        const data=s.image.img.getContext('2d').getImageData(0,0,80,80).data;
        for(let p=0;p<80;p++)for(const edge of [p,79*80+p,p*80,p*80+79]){
          if(data[edge*4+3])throw Error(`Clipped assembled car ${i}, heading ${heading}, slope ${slope}`);
        }
      }
      for(let d=0;d<4;d++){r.display(s,[16,4,8,12][d],0);g.drawImage(s.image.img,i*200+d*44-10,40,90,90);}
      r.display(s,2,0);g.drawImage(s.image.img,i*200-20,115,240,240);r.dispose();
    }
    renderer.dispose();
    return {uniqueFrames:frames.size,changedWithParts:bare!==red&&red!==green,frontCrate,rearCrate,gallery:gallery.toDataURL(),disposed:renderer.display(s,1,0)};
  });
  assert.equal(result.uniqueFrames,80);
  assert.equal(result.changedWithParts,true);
  assert.equal(result.disposed,false);
  assert.ok(result.rearCrate-result.frontCrate>12,'Shared crate artwork must move to the mounted end');
  fs.writeFileSync('docs/overworld-car-examples.png',Buffer.from(result.gallery.split(',')[1],'base64'));
  // Exercise the loader failure path in a fresh browser context.
  const context=await browser.newContext();const fallback=await context.newPage();
  let customRequests=0;
  fallback.on('request',request=>{if(request.url().includes('/overworld-parts/'))customRequests++;});
  await fallback.route('**/overworld-parts/manifest.json',route=>route.fulfill({status:503,body:'unavailable'}));
  await fallback.goto(`${base}/?movie=05&user=FallbackQA`);
  await fallback.locator('#startText').filter({hasText:'Klicka'}).waitFor({timeout:90000});
  assert.equal(await fallback.locator('#customCarAssetsBox').isChecked(),false);
  await fallback.locator('#startText').click();
  await fallback.waitForFunction(()=>window.G?.dir?.mode==='Showing'||window.G?.dir?.mode==='Driving');
  await fallback.evaluate(()=>{window.makeCar('Good');window.G.dir.send('ShowOff','fakeMouse');});
  await fallback.waitForFunction(()=>window.G?.dir?.mode==='Driving');
  assert.notEqual(await fallback.evaluate(()=>window.G.dir.display.sprite.member.info.name),'AssembledOverworldCar');
  assert.equal(customRequests,0,'Original graphics mode must not load custom artwork');
  await fallback.reload();
  await fallback.locator('#startText').filter({hasText:'Klicka'}).waitFor({timeout:90000});
  await fallback.locator('#customCarAssetsBox').check();
  await fallback.locator('#startText').click();
  await fallback.waitForFunction(()=>window.G?.dir?.mode==='Showing'||window.G?.dir?.mode==='Driving');
  await fallback.evaluate(()=>{window.makeCar('Good');window.G.dir.send('ShowOff','fakeMouse');});
  await fallback.waitForFunction(()=>window.G?.dir?.mode==='Driving');
  await fallback.waitForFunction(()=>window.G.dir.display.sprite.member.info.name!=='Dummy');
  assert.notEqual(await fallback.evaluate(()=>window.G.dir.display.sprite.member.info.name),'AssembledOverworldCar');
  assert.ok(customRequests>0,'Enabled graphics must attempt to load artwork');
  await context.close();
  assert.deepEqual(errors,[]);
  console.log(JSON.stringify({initial,coverage,uniqueFrames:result.uniqueFrames,changedWithParts:result.changedWithParts,morphPlacement:true,originalFallback:true,pageErrors:errors},null,2));
} finally {await browser.close();}

