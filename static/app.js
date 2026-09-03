const $=s=>document.querySelector(s), $$=s=>document.querySelectorAll(s);
const form=$('#convertForm'), drop=$('#dropZone'), video=$('#videoInput'), images=$('#imageInput'), interval=$('#interval'), customRow=$('#customRow');
let tool='video', currentUrl=null, activeView='home';
const views={home:$('#homeView'),tool:$('#toolView'),history:$('#historyView'),settings:$('#settingsView')};

function motionTick(el, cls='motion-pop'){if(!el)return;el.classList.remove(cls);void el.offsetWidth;el.classList.add(cls);setTimeout(()=>el.classList.remove(cls),520)}

function setView(view){
 activeView=view; document.body.classList.add('theme-transition'); setTimeout(()=>document.body.classList.remove('theme-transition'),450); Object.entries(views).forEach(([k,v])=>v.classList.toggle('hidden',k!==view));
 $$('.nav').forEach(b=>b.classList.toggle('active',b.dataset.view===view || (view==='tool'&&b.dataset.tool===tool)));
 const labels={home:['HOME','Your workspace'],tool:[tool==='video'?'VIDEO → PDF':'IMAGES → PDF',tool==='video'?'Video → PDF':'Images → PDF'],history:['HISTORY','Conversion history'],settings:['SETTINGS','Settings']};
 $('#crumbPage').textContent=labels[view][0]; $('#title').textContent=labels[view][1];
 if(view==='home') renderRecent(); if(view==='history') renderHistory();
}
function setTool(next){
 tool=next; setView('tool');
 $$('.nav').forEach(b=>b.classList.toggle('active',b.dataset.tool===tool));
 $('#title').textContent=tool==='video'?'Video → PDF':'Images → PDF'; $('#crumbPage').textContent=tool==='video'?'VIDEO → PDF':'IMAGES → PDF';
 $('#chooseTitle').textContent=tool==='video'?'Choose your video':'Choose your images';
 $('#chooseSub').textContent=tool==='video'?'Drop a file below or browse your computer.':'Add one or more images and arrange your document.';
 $('#dropTitle').textContent=tool==='video'?'Drop your video here':'Drop your images here';
 $('#dropSub').textContent='or click anywhere to browse files';
 $('#formats').textContent=tool==='video'?'MP4 · MOV · MKV · AVI · WEBM · M4V':'JPG · JPEG · PNG · WEBP · BMP · TIFF';
 $('#videoSettings').classList.toggle('hidden',tool!=='video'); $('#imageSettings').classList.toggle('hidden',tool!=='images');
 drop.classList.remove('has-file'); $('#fileInfo').textContent=''; $('#preview').innerHTML='<span class="preview-icon">✦</span><span><b>Preview</b><small>Your selected file will appear here</small></span>';
}
$$('[data-view]').forEach(b=>b.addEventListener('click',()=>setView(b.dataset.view)));
$$('[data-tool]').forEach(b=>b.addEventListener('click',()=>setTool(b.dataset.tool)));

drop.addEventListener('click',()=> (tool==='video'?video:images).click());
['dragenter','dragover'].forEach(e=>drop.addEventListener(e,ev=>{ev.preventDefault();drop.classList.add('over')}));
['dragleave','drop'].forEach(e=>drop.addEventListener(e,ev=>{ev.preventDefault();drop.classList.remove('over')}));
drop.addEventListener('drop',ev=>{const input=tool==='video'?video:images;if(ev.dataTransfer.files.length){try{input.files=ev.dataTransfer.files}catch(_){return}showFiles()}});
video.addEventListener('change',showFiles); images.addEventListener('change',showFiles);
function showFiles(){const input=tool==='video'?video:images, fs=[...input.files]; if(!fs.length)return; $('#fileInfo').textContent=fs.length===1?fs[0].name:`${fs.length} images selected`;drop.classList.add('has-file');motionTick(drop,'file-selected');
 if(currentUrl)URL.revokeObjectURL(currentUrl); const f=fs[0]; currentUrl=URL.createObjectURL(f);
 if(tool==='video') $('#preview').innerHTML='<video controls muted preload="metadata"></video>'; else $('#preview').innerHTML='<img alt="Preview"><span><b>'+fs.length+' image'+(fs.length>1?'s':'')+'</b><small>Ready to build your PDF</small></span>';
 if(tool==='video') $('#preview video').src=currentUrl; else $('#preview img').src=currentUrl;
}
interval.addEventListener('change',()=>customRow.classList.toggle('hidden',interval.value!=='custom'));
function setBusy(b){$('#convertBtn').disabled=b;$('#convertBtn').classList.toggle('loading',b)}
function historyKey(){return 'mimi_baby_history_v10'}
function getHistory(){try{return JSON.parse(localStorage.getItem(historyKey())||'[]')}catch(_){return []}}
function saveHistory(item){const h=getHistory();h.unshift(item);localStorage.setItem(historyKey(),JSON.stringify(h.slice(0,20)))}
function escapeHtml(s){return String(s).replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]))}
function historyMarkup(h){if(!h.length)return '<div class="empty-state"><span>♡</span><b>No conversions yet</b><small>Your finished PDFs will appear here.</small><button class="hero-btn primary" data-tool="video">Create your first PDF →</button></div>';return h.map((x,i)=>`<div class="history-item"><div class="file-icon">PDF</div><div class="history-main"><b>${escapeHtml(x.name)}</b><small>${escapeHtml(x.type)} · ${escapeHtml(x.date)}</small></div><a class="open-link" href="${escapeHtml(x.download||'#')}" ${x.download?'target="_blank" rel="noopener"':''}>${x.download?'Open':'Saved locally'} ↗</a><button class="delete-one" data-index="${i}" title="Remove">×</button></div>`).join('')}
function renderHistory(){$('#historyList').innerHTML=historyMarkup(getHistory()); $$('#historyList .delete-one').forEach(b=>b.addEventListener('click',()=>{const h=getHistory();h.splice(+b.dataset.index,1);localStorage.setItem(historyKey(),JSON.stringify(h));renderHistory()})); $$('#historyList [data-tool]').forEach(b=>b.addEventListener('click',()=>setTool(b.dataset.tool)))}
function renderRecent(){updateTodayStats();const h=getHistory().slice(0,4);$('#homeRecent').innerHTML=h.length?h.map(x=>`<div class="recent-item"><div class="file-icon">PDF</div><div><b>${escapeHtml(x.name)}</b><small>${escapeHtml(x.type)} · ${escapeHtml(x.date)}</small></div><a href="${escapeHtml(x.download||'#')}" ${x.download?'target="_blank" rel="noopener"':''}>Open ↗</a></div>`).join(''):'<div class="mini-empty">No recent conversions yet. Start by choosing a tool above.</div>'}

let pendingConversion=null;
function formatFileSize(bytes){if(!bytes)return '0 B';const units=['B','KB','MB','GB'];let n=bytes,i=0;while(n>=1024&&i<units.length-1){n/=1024;i++}return `${n>=10||i===0?n.toFixed(0):n.toFixed(1)} ${units[i]}`}
function openStartModal(){
 const input=tool==='video'?video:images, fs=[...input.files]; if(!fs.length)return;
 const panel=tool==='video'?$('#videoSettings'):$('#imageSettings'), name=panel.querySelector('[name="output_name"]');
 const total=fs.reduce((sum,f)=>sum+f.size,0);
 $('#startFileCount').textContent=fs.length===1?`1 ${tool==='video'?'video':'image'} selected`:`${fs.length} ${tool==='video'?'videos':'images'} selected`;
 $('#startFileSize').textContent=`Total size: ${formatFileSize(total)}`;
 $('#startModal').classList.remove('hidden'); motionTick($('#startModal .start-card'),'modal-start-pop');
 pendingConversion={files:fs,panel,name:name?.value||'Mimi_Baby_Document'};
 $('#startConversionBtn').focus();
}
function closeStartModal(){pendingConversion=null;$('#startModal').classList.add('hidden')}
async function beginConversion(){
 if(!pendingConversion)return;
 const {files,panel,name}=pendingConversion; pendingConversion=null; $('#startModal').classList.add('hidden');
 const fd=new FormData();fd.set('tool',tool);files.forEach(f=>fd.append(tool==='video'?'video':'images',f));panel.querySelectorAll('input[name],select[name]').forEach(el=>{if(el.type==='checkbox'){if(el.checked)fd.set(el.name,'on')}else if(el.name!=='output_name')fd.set(el.name,el.value)});fd.set('output_name',name);if(tool==='video'&&interval.value==='custom')fd.set('interval',$('#customInterval').value);
 $('#errorBox').classList.add('hidden');$('#progressWrap').classList.remove('hidden');$('#consoleWrap').classList.toggle('hidden',tool!=='video');$('#consoleBox').textContent='Waiting for FFmpeg…';$('#progressBar').style.width='4%';$('#progressPercent').textContent='4%';$('#progressText').textContent=tool==='video'?'Preparing video…':'Preparing images…';showConversionProgress(name);setBusy(true);
 try{const r=await fetch('/convert',{method:'POST',body:fd});const data=await r.json();if(!r.ok)throw Error(data.error||'Conversion failed');poll(data.job_id,name)}catch(err){showError(err.message);hideConversionProgress();setBusy(false);$('#progressWrap').classList.add('hidden');$('#consoleWrap').classList.add('hidden')}}
form.addEventListener('submit',e=>{e.preventDefault();const input=tool==='video'?video:images;if(!input.files.length){showError(tool==='video'?'Please select a video first.':'Please select at least one image.');return}openStartModal()});
$('#startConversionBtn').addEventListener('click',beginConversion);$('#startCancelBtn').addEventListener('click',closeStartModal);$('#startModalClose').addEventListener('click',closeStartModal);$('#startModal').addEventListener('click',e=>{if(e.target.id==='startModal')closeStartModal()});

function formatBytes(bytes){const n=Number(bytes);if(!Number.isFinite(n)||n<0)return 'Size unavailable';if(n<1024)return `${n} B`;if(n<1024*1024)return `${(n/1024).toFixed(1)} KB`;if(n<1024*1024*1024)return `${(n/1024/1024).toFixed(2)} MB`;return `${(n/1024/1024/1024).toFixed(2)} GB`}
async function poll(id,outputName){try{const r=await fetch('/status/'+id);const d=await r.json();if(d.status==='error')throw Error(d.message||'Conversion failed');const p=Math.max(0,Math.min(100,d.progress||0));if(tool==='video'&&d.logs){const box=$('#consoleBox');box.textContent=d.logs.join('\n');box.scrollTop=box.scrollHeight}$('#progressBar').style.width=p+'%';$('#progressPercent').textContent=p+'%';$('#progressText').textContent=d.message||'Working…';updateConversionProgress(p,d.message||'Working…');if(d.status==='done'){hideConversionProgress();setBusy(false);const finalName=(outputName||'Mimi_Baby_Document').replace(/\.pdf$/i,'')+'.pdf';$('#openPdfLink').href=d.download;$('#downloadLink').href=d.download;$('#downloadLink').setAttribute('download',finalName);$('#successFileName').textContent=finalName;$('#successFileMeta').textContent=`Ready to view · ${formatBytes(d.filesize)} · Just now`;$('#successModal').classList.remove('hidden');saveHistory({name:finalName,type:tool==='video'?'Video → PDF':'Images → PDF',date:new Date().toLocaleString([], {month:'short',day:'numeric',hour:'numeric',minute:'2-digit'}),download:d.download,size:d.filesize});renderRecent();return}setTimeout(()=>poll(id,outputName),500)}catch(e){hideConversionProgress();showError(e.message);setBusy(false)}}

function showConversionProgress(name){
 const m=$('#conversionModal'); if(!m)return;
 $('#conversionFile').textContent=`Preparing ${name.replace(/\.pdf$/i,'')}.pdf on this computer.`;
 $('#conversionTitle').textContent=tool==='video'?'Creating your video PDF…':'Creating your image PDF…';
 $('#conversionStage').textContent=tool==='video'?'Preparing video…':'Preparing images…';
 $('#conversionPercent').textContent='4%'; $('#conversionBar').style.width='4%';
 m.classList.remove('hidden');
}
function updateConversionProgress(p,message){
 const m=$('#conversionModal'); if(!m)return;
 $('#conversionPercent').textContent=p+'%'; $('#conversionBar').style.width=p+'%'; $('#conversionStage').textContent=message;
}
function hideConversionProgress(){const m=$('#conversionModal');if(m)m.classList.add('hidden')}

function showError(s){$('#errorBox').textContent=s;$('#errorBox').classList.remove('hidden')}
$('#clearConsole').addEventListener('click',()=>$('#consoleBox').textContent='Console cleared.\n');
$('#closeModal').addEventListener('click',()=>$('#successModal').classList.add('hidden'));$('#convertAnother').addEventListener('click',()=>{$('#successModal').classList.add('hidden');drop.scrollIntoView({behavior:'smooth',block:'center'});});$('#successModal').addEventListener('click',e=>{if(e.target.id==='successModal')e.currentTarget.classList.add('hidden')});document.addEventListener('keydown',e=>{if(e.key==='Escape'){if(!$('#startModal').classList.contains('hidden'))closeStartModal();else $('#successModal').classList.add('hidden')}});
$('#clearHistory').addEventListener('click',async()=>{
 if(!confirm('Clear all conversion history and temporary files?'))return;
 localStorage.removeItem(historyKey()); renderHistory(); renderRecent(); updateTodayStats();
 try{const r=await fetch('/cleanup',{method:'POST'}); const d=await r.json(); if(d.ok) alert(`History cleared. ${d.removed} temporary item${d.removed===1?'':'s'} removed from local storage.`); else throw Error('Cleanup failed');}
 catch(_){alert('History cleared, but temporary-file cleanup could not be completed. You can run the cleanup again later.');}
});
function updateTodayStats(){
 const h=getHistory(); const now=new Date(); const today=now.toDateString();
 const todayItems=h.filter(x=>{const d=new Date(x.date);return !Number.isNaN(d.getTime())&&d.toDateString()===today});
 const count=todayItems.length; const total=h.length;
 const el=$('#todayCount'); if(el)el.textContent=count;
 const totalEl=$('#totalCount'); if(totalEl)totalEl.textContent=`${total} total`;
 const txt=$('#todayProgressText'); if(txt)txt.textContent=count?`${count} file${count===1?'':'s'} converted today.`:'No conversions today yet.';
 const last=$('#lastActivity');
 if(last){
   if(h.length){const d=new Date(h[0].date); last.textContent=Number.isNaN(d.getTime())?'Recent activity':`Last: ${d.toLocaleTimeString([], {hour:'numeric',minute:'2-digit'})}`;}
   else last.textContent='No recent activity';
 }
 const ring=$('.activity-ring');
 if(ring){
   const pct=total?Math.min(100,(count/total)*100):0;
   ring.style.setProperty('--activity-angle',`${pct*3.6}deg`);
   ring.classList.toggle('has-activity',count>0);
 }
}
function updateGreeting(){
 const h=new Date().getHours();
 let greeting, eyebrow;
 if(h>=5 && h<12){greeting='Good morning'; eyebrow='♡ A FRESH START FOR TODAY';}
 else if(h>=12 && h<17){greeting='Good afternoon'; eyebrow='♡ YOUR LITTLE WORK HELPER';}
 else if(h>=17 && h<21){greeting='Good evening'; eyebrow='♡ YOUR LITTLE WORK HELPER';}
 else {greeting='Good night'; eyebrow='♡ WINDING DOWN WITH MIMI Baby Studio';}
 const g=$('#greetingText'); if(g)g.textContent=greeting;
 const e=$('#welcomeEyebrow'); if(e)e.textContent=eyebrow;
}
updateGreeting(); setInterval(updateGreeting,60000);

// v13.1 — MIMI Baby Studio animated sticker gallery
const stickerGallery=[
  ['stickers/bunny-love.gif','Bunny Love'],
  ['stickers/cute-girl-love.gif','Cute Girl Love'],
  ['stickers/happy-in-love.gif','Happy in Love'],
  ['stickers/hungry-cat.gif','Hungry Cat'],
  ['stickers/miss-you.gif','I Miss You']
];
let stickerIndex=0;
const stickerImage=$('#stickerImage');
const stickerButton=$('#dashboardSticker');
function setSticker(index){
  if(!stickerImage)return;
  stickerIndex=(index+stickerGallery.length)%stickerGallery.length;
  stickerImage.classList.remove('sticker-swap');
  void stickerImage.offsetWidth;
  stickerImage.src='/static/'+stickerGallery[stickerIndex][0];
  stickerImage.alt=stickerGallery[stickerIndex][1]+' animated sticker';
  stickerImage.classList.add('sticker-swap');
}
if(stickerButton)stickerButton.addEventListener('click',()=>setSticker(stickerIndex+1));
if(stickerImage){
  const stickerTimer=setInterval(()=>{
    if(document.hidden)return;
    setSticker(stickerIndex+1);
  },9000);
}

// v13.4 — fresh motivational quote on every app open
const fallbackQuotes=[
  ['Small steps every day add up to big results.','Unknown'],
  ['You are capable of more than you know.','Unknown'],
  ['Believe you can, and you are halfway there.','Theodore Roosevelt'],
  ['Success is the sum of small efforts, repeated day in and day out.','Robert Collier'],
  ['Start where you are. Use what you have. Do what you can.','Arthur Ashe'],
  ['The secret of getting ahead is getting started.','Mark Twain'],
  ['Great things are done by a series of small things brought together.','Vincent van Gogh'],
  ['Keep going. Your future self will thank you.','Unknown']
];
function setDailyQuote(q,a){
 const quote=$('#dailyQuote'), author=$('#dailyQuoteAuthor');
 if(!quote)return;
 quote.textContent='“'+q+'”';
 if(author)author.textContent=a&&a!=='Unknown'?' — '+a:'';
}
async function loadDailyQuote(){
 const local=fallbackQuotes[Math.floor(Math.random()*fallbackQuotes.length)];
 setDailyQuote(local[0],local[1]);
 try{
   const controller=new AbortController(); const timer=setTimeout(()=>controller.abort(),3500);
   const r=await fetch('https://dummyjson.com/quotes/random?cb='+Date.now(),{cache:'no-store',signal:controller.signal,headers:{'Accept':'application/json'}});
   clearTimeout(timer);
   if(!r.ok)throw Error('quote request failed');
   const d=await r.json();
   if(d&&typeof d.quote==='string'&&d.quote.trim())setDailyQuote(d.quote.trim(),typeof d.author==='string'?d.author.trim():'');
 }catch(_){/* keep local fallback so the top bar is never empty */}
}
loadDailyQuote();
// v13.7 — Calm local music player
const workMusic=$('#workMusic'), musicPlay=$('#musicPlay'), musicSeek=$('#musicSeek'), musicMute=$('#musicMute'), musicLoop=$('#musicLoop'), musicCurrent=$('#musicCurrent'), musicDuration=$('#musicDuration'), musicStatus=$('#musicStatus'), musicVolume=$('#musicVolume');
function fmtTime(sec){if(!Number.isFinite(sec))return '0:00';const m=Math.floor(sec/60),ss=Math.floor(sec%60).toString().padStart(2,'0');return m+':'+ss}
function syncMusic(){if(!workMusic)return;workMusic.dataset.playing=workMusic.paused?'0':'1';if(musicVolume)musicVolume.value=Math.round((workMusic.muted?0:workMusic.volume)*100);const d=workMusic.duration||0; if(musicSeek)musicSeek.value=d?(workMusic.currentTime/d*100):0; if(musicCurrent)musicCurrent.textContent=fmtTime(workMusic.currentTime); if(musicDuration)musicDuration.textContent=fmtTime(d); if(musicPlay){musicPlay.textContent=workMusic.paused?'▶':'❚❚';musicPlay.setAttribute('aria-label',workMusic.paused?'Play music':'Pause music');musicPlay.title=workMusic.paused?'Play music':'Pause music'} if(musicStatus)musicStatus.textContent=workMusic.paused?'OFF':'ON'}
if(workMusic){
  const savedVolume=Number(localStorage.getItem('mimi_music_volume'));
  workMusic.volume=Number.isFinite(savedVolume)?Math.min(1,Math.max(0,savedVolume)):0.70;
  workMusic.loop=true;
  musicPlay?.addEventListener('click',async()=>{try{if(workMusic.paused)await workMusic.play();else workMusic.pause()}catch(_){}});
  workMusic.addEventListener('loadedmetadata',syncMusic); workMusic.addEventListener('timeupdate',syncMusic); workMusic.addEventListener('play',syncMusic); workMusic.addEventListener('pause',syncMusic); workMusic.addEventListener('ended',syncMusic);
  musicSeek?.addEventListener('input',()=>{if(workMusic.duration)workMusic.currentTime=(Number(musicSeek.value)/100)*workMusic.duration});
  musicVolume?.addEventListener('input',()=>{const v=Math.min(1,Math.max(0,Number(musicVolume.value)/100));workMusic.volume=v;workMusic.muted=v===0;localStorage.setItem('mimi_music_volume',String(v));musicMute.textContent=workMusic.muted?'🔇':'🔊';musicMute.setAttribute('aria-label',workMusic.muted?'Unmute music':'Mute music');syncMusic()});
  musicMute?.addEventListener('click',()=>{if(workMusic.muted||workMusic.volume===0){const restore=Number(localStorage.getItem('mimi_music_volume'));workMusic.muted=false;workMusic.volume=Number.isFinite(restore)&&restore>0?restore:0.70}else{localStorage.setItem('mimi_music_volume',String(workMusic.volume));workMusic.muted=true}musicMute.textContent=workMusic.muted?'🔇':'🔊';musicMute.setAttribute('aria-label',workMusic.muted?'Unmute music':'Mute music');syncMusic()});
  musicLoop?.addEventListener('change',()=>workMusic.loop=musicLoop.checked);
  syncMusic();
}


const COMFORT_THEMES={
  'sage-green':'Sage Green',
  'warm-beige':'Warm Beige',
  'soft-blue':'Soft Blue',
  'lavender':'Lavender',
  'warm-olive':'Warm Olive'
};
function applyTheme(theme){
  if(!COMFORT_THEMES[theme]) theme='sage-green';
  document.body.classList.add('theme-transition');
  document.body.dataset.theme=theme;
  document.body.classList.remove('dark');
  localStorage.setItem('mimi_theme_v12',theme);
  localStorage.setItem('mimi_theme',theme);
  const current=$('#themeCurrent'); if(current) current.textContent=COMFORT_THEMES[theme];
  $$('#themeGrid .theme-card').forEach(b=>b.classList.toggle('selected',b.dataset.theme===theme));
  setTimeout(()=>document.body.classList.remove('theme-transition'),450);
}
$$('#themeGrid .theme-card').forEach(card=>card.addEventListener('click',()=>applyTheme(card.dataset.theme)));
const themeOrder=Object.keys(COMFORT_THEMES);
$('#themeCycle')?.addEventListener('click',()=>{const current=document.body.dataset.theme||'sage-green';const next=themeOrder[(themeOrder.indexOf(current)+1)%themeOrder.length];applyTheme(next)});
const savedTheme=localStorage.getItem('mimi_theme')||'sage-green';
applyTheme(savedTheme);setView('home');renderRecent();


// Local Flask server status / reconnect control
const serverStatus=$('#serverStatus'), serverStatusText=$('#serverStatusText');
let serverOnline=true;
function setServerStatus(online){
  serverOnline=!!online;
  if(!serverStatus)return;
  serverStatus.classList.toggle('online',serverOnline);
  serverStatus.classList.toggle('offline',!serverOnline);
  serverStatusText.textContent=serverOnline?'Server Online':'Server Offline';
  serverStatus.title=serverOnline?'MIMI Baby Studio server is running • Click to check again':'Server is not responding • Click to start/reconnect';
  serverStatus.setAttribute('aria-label',serverStatus.title);
}
async function checkServerStatus(){
  try{
    const c=new AbortController(); const t=setTimeout(()=>c.abort(),1800);
    const r=await fetch('/health?cb='+Date.now(),{cache:'no-store',signal:c.signal}); clearTimeout(t);
    if(!r.ok)throw Error('offline');
    setServerStatus(true);
  }catch(_){setServerStatus(false)}
}
serverStatus?.addEventListener('click',()=>{
  if(serverOnline){checkServerStatus(); return;}
  // Registered by start.bat on Windows. It launches the silent local server.
  try{window.location.href='mimibaby://start';}catch(_){ }
  serverStatusText.textContent='Starting server…';
  serverStatus.classList.remove('offline'); serverStatus.classList.add('starting');
  setTimeout(checkServerStatus,1200); setTimeout(checkServerStatus,3000); setTimeout(checkServerStatus,6000);
});
checkServerStatus();
setInterval(checkServerStatus,5000);
