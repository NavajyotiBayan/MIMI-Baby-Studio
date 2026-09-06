import os, shutil, subprocess, threading, uuid, re
from pathlib import Path
from flask import Flask, render_template, request, jsonify, send_file

BASE=Path(__file__).resolve().parent
TEMP=BASE/'temp'; TEMP.mkdir(exist_ok=True)
app=Flask(__name__); app.config['MAX_CONTENT_LENGTH']=2*1024*1024*1024
jobs={}

# Prevent FFmpeg/FFprobe from opening a Windows console window.
NO_WINDOW = getattr(subprocess, 'CREATE_NO_WINDOW', 0)

def job_log(job_id, text):
    text=str(text).strip()
    if not text: return
    j=jobs.get(job_id)
    if j is None: return
    logs=j.setdefault('logs', [])
    logs.append(text)
    if len(logs)>180: del logs[:-180]

VIDEO_EXT={'.mp4','.mkv','.mov','.avi','.webm','.m4v'}
IMAGE_EXT={'.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff'}

def find_ffmpeg():
    exe=shutil.which('ffmpeg')
    if exe:return exe
    roots=[Path(os.path.expandvars(r'%LOCALAPPDATA%/Microsoft/WinGet/Links')),Path(os.path.expandvars(r'%LOCALAPPDATA%/Microsoft/WinGet/Packages')),Path(r'C:/ffmpeg/bin')]
    for root in roots:
        if root.exists():
            for p in root.rglob('ffmpeg.exe'):
                return str(p)
    return None

def safe_name(name, fallback):
    name=(name or '').strip()
    name=re.sub(r'[<>:"/\\|?*\x00-\x1f]','_',name).strip('. ')
    return (name or fallback)[:150]

def fit_image(img, box_w, box_h, mode='fit'):
    from PIL import Image
    if mode=='fill':
        scale=max(box_w/img.width, box_h/img.height)
        size=(max(1,int(img.width*scale)),max(1,int(img.height*scale)))
        img=img.resize(size,Image.Resampling.LANCZOS)
        left=(img.width-box_w)//2; top=(img.height-box_h)//2
        return img.crop((left,top,left+box_w,top+box_h))
    if mode=='original': return img.copy()
    scale=min(box_w/img.width,box_h/img.height)
    size=(max(1,int(img.width*scale)),max(1,int(img.height*scale)))
    return img.resize(size,Image.Resampling.LANCZOS)

def build_image_pdf(job_id, paths, settings):
    from PIL import Image, ImageOps, ImageDraw
    work=TEMP/job_id; work.mkdir(parents=True,exist_ok=True)
    jobs[job_id].update(status='building',message='Preparing your images…',progress=5)
    try:
        size=settings['page_size']; orient=settings['orientation']
        dims={'A4':(1240,1754),'Letter':(1275,1650),'Standard':(1600,2200)}[size]
        PW,PH=dims if orient=='portrait' else (dims[1],dims[0])
        margin={'small':35,'medium':65,'large':100}.get(settings['margins'],65)
        per=max(1,min(4,int(settings['per_page'])))
        cols=2 if per>=2 else 1; rows=(per+cols-1)//cols
        gap=25; cell_w=(PW-2*margin-(cols-1)*gap)//cols; cell_h=(PH-2*margin-(rows-1)*gap)//rows
        pages=[]
        for start in range(0,len(paths),per):
            page=Image.new('RGB',(PW,PH),'white'); batch=paths[start:start+per]
            for n,path in enumerate(batch):
                try: im=Image.open(path).convert('RGB')
                except Exception: continue
                fitted=fit_image(im,cell_w,cell_h,settings['fit'])
                x=margin+(n%cols)*(cell_w+gap)+(cell_w-fitted.width)//2
                y=margin+(n//cols)*(cell_h+gap)+(cell_h-fitted.height)//2
                page.paste(fitted,(x,y))
            pages.append(page)
            jobs[job_id]['progress']=int(10+(start+len(batch))/len(paths)*85)
        if not pages: raise RuntimeError('No valid images were found.')
        output=work/'converted.pdf'
        pages[0].save(output,'PDF',resolution=150.0,save_all=True,append_images=pages[1:])
        jobs[job_id].update(status='done',progress=100,message='PDF ready',output=str(output),filename=settings['filename']+'.pdf',filesize=output.stat().st_size)
    except Exception as e:
        jobs[job_id].update(status='error',message=str(e))

def build_video_pdf(job_id, video_path, settings):
    from PIL import Image, ImageDraw, ImageFont
    work=TEMP/job_id; frames=work/'frames'; frames.mkdir(parents=True,exist_ok=True)
    jobs[job_id].update(status='extracting',message='Extracting video frames…',progress=3)
    ffmpeg=find_ffmpeg()
    if not ffmpeg: jobs[job_id].update(status='error',message='FFmpeg was not found. Run start.bat again.'); return
    interval=float(settings['interval']); pattern=str(frames/'frame_%06d.jpg')
    job_log(job_id, f'FFmpeg: {Path(ffmpeg).name}')
    job_log(job_id, f'Input: {video_path.name}')
    try:
        probe=subprocess.run([ffmpeg,'-hide_banner','-v','error','-show_entries','format=duration','-of','default=noprint_wrappers=1:nokey=1','-i',str(video_path)],capture_output=True,text=True,creationflags=NO_WINDOW)
        duration=float(probe.stdout.strip() or 0)
    except Exception:
        duration=0
    cmd=[ffmpeg,'-hide_banner','-loglevel','warning','-stats_period','0.5','-progress','pipe:1','-y','-i',str(video_path),'-vf',f'fps=1/{interval}','-q:v','2',pattern]
    job_log(job_id, 'Starting frame extraction…')
    try:
        proc=subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,bufsize=1,creationflags=NO_WINDOW)
        last_time=0.0
        for raw in proc.stdout:
            line=raw.strip()
            if not line: continue
            if line.startswith('out_time_ms='):
                try: last_time=float(line.split('=',1)[1])/1_000_000
                except Exception: pass
                if duration>0:
                    pct=min(34,int((last_time/duration)*32)+3)
                    jobs[job_id]['progress']=pct
                continue
            if line.startswith('progress='):
                if line.endswith('end'): jobs[job_id]['progress']=34
                continue
            if line.startswith(('frame=', 'fps=', 'size=', 'time=', 'bitrate=', 'speed=')):
                continue
            job_log(job_id,line)
        rc=proc.wait()
    except Exception as e:
        jobs[job_id].update(status='error',message='Could not start FFmpeg: '+str(e)); job_log(job_id,'ERROR: '+str(e)); return
    if rc!=0:
        jobs[job_id].update(status='error',message='FFmpeg failed. See the console below for details.'); return
    job_log(job_id,'Frame extraction complete.')
    files=sorted(frames.glob('frame_*.jpg'))
    if not files: jobs[job_id].update(status='error',message='No frames were extracted.'); return
    jobs[job_id].update(status='building',message='Building your PDF…',progress=35)
    PW,PH=(1240,1754) if settings['orientation']=='portrait' else (1754,1240)
    per=max(1,min(9,int(settings['per_page']))); cols=3 if per>=6 else (2 if per>=4 else 1); rows=(per+cols-1)//cols
    margin,gap=45,20; cw=(PW-2*margin-(cols-1)*gap)//cols; ch=(PH-2*margin-(rows-1)*gap)//rows
    try: font=ImageFont.truetype('arial.ttf',22)
    except Exception: font=None
    pages=[]; total=len(files)
    for start in range(0,total,per):
        page=Image.new('RGB',(PW,PH),'white'); draw=ImageDraw.Draw(page); batch=files[start:start+per]
        for n,f in enumerate(batch):
            im=Image.open(f).convert('RGB'); label_h=35 if settings['timestamps'] else 0; im.thumbnail((cw,max(1,ch-label_h)))
            col,row=n%cols,n//cols; x=margin+col*(cw+gap)+(cw-im.width)//2; y=margin+row*(ch+gap)+(max(1,ch-label_h)-im.height)//2; page.paste(im,(x,y))
            if settings['timestamps']:
                sec=int((start+n)*interval); label=f'{sec//3600:02d}:{sec%3600//60:02d}:{sec%60:02d}'; bb=draw.textbbox((0,0),label,font=font); draw.text((margin+col*(cw+gap)+(cw-(bb[2]-bb[0]))//2, y+im.height+5),label,fill='black',font=font)
        pages.append(page); jobs[job_id]['progress']=int(35+(start+len(batch))/total*60)
    output=work/'converted.pdf'; pages[0].save(output,'PDF',resolution=150.0,save_all=True,append_images=pages[1:])
    jobs[job_id].update(status='done',progress=100,message='PDF ready',output=str(output),filename=settings['filename']+'.pdf',filesize=output.stat().st_size)

@app.route('/cleanup', methods=['POST'])
def cleanup():
    removed = 0
    TEMP.mkdir(exist_ok=True)
    for child in list(TEMP.iterdir()):
        try:
            if child.is_dir():
                shutil.rmtree(child, ignore_errors=False)
            else:
                child.unlink()
            removed += 1
        except Exception:
            pass
    jobs.clear()
    return jsonify(ok=True, removed=removed)

@app.route('/health')
def health():
    return jsonify(status='online', service='MIMI Baby Studio')

@app.route('/')
def index(): return render_template('index.html')

@app.route('/convert',methods=['POST'])
def convert():
    tool=request.form.get('tool','video')
    job_id=uuid.uuid4().hex; work=TEMP/job_id; work.mkdir(parents=True,exist_ok=True)
    if tool=='images':
        files=request.files.getlist('images'); files=[f for f in files if f and f.filename]
        if not files:return jsonify(error='Please select at least one image.'),400
        saved=[]
        for i,f in enumerate(files):
            ext=Path(f.filename).suffix.lower()
            if ext not in IMAGE_EXT:return jsonify(error=f'Unsupported image format: {ext}'),400
            p=work/f'{i:05d}{ext}'; f.save(p); saved.append(p)
        settings={'page_size':request.form.get('page_size','A4'),'orientation':request.form.get('orientation','portrait'),'per_page':request.form.get('per_page','1'),'fit':request.form.get('fit','fit'),'margins':request.form.get('margins','medium'),'filename':safe_name(request.form.get('output_name'),'Mimi_Baby_Document')}
        jobs[job_id]={'status':'queued','progress':0,'message':'Starting…','logs':[]}
        threading.Thread(target=build_image_pdf,args=(job_id,saved,settings),daemon=True).start()
        return jsonify(job_id=job_id)
    f=request.files.get('video')
    if not f or not f.filename:return jsonify(error='Please select a video first.'),400
    ext=Path(f.filename).suffix.lower()
    if ext not in VIDEO_EXT:return jsonify(error='Unsupported video format.'),400
    try: interval=float(request.form.get('interval','10')); per=int(request.form.get('per_page','6'))
    except ValueError:return jsonify(error='Invalid conversion settings.'),400
    if interval<0.1 or interval>3600:return jsonify(error='Invalid frame interval.'),400
    p=work/('input'+ext); f.save(p)
    settings={'interval':interval,'per_page':per,'orientation':request.form.get('orientation','landscape'),'timestamps':request.form.get('timestamps')=='on','filename':safe_name(request.form.get('output_name'),Path(f.filename).stem)}
    jobs[job_id]={'status':'queued','progress':0,'message':'Starting…','logs':[]}
    threading.Thread(target=build_video_pdf,args=(job_id,p,settings),daemon=True).start()
    return jsonify(job_id=job_id)

@app.route('/status/<job_id>')
def status(job_id):
    if job_id not in jobs:return jsonify(error='Job not found'),404
    j=jobs[job_id].copy()
    if j.get('status')=='done':j['download']=f'/download/{job_id}'
    return jsonify(j)

@app.route('/download/<job_id>')
def download(job_id):
    j=jobs.get(job_id)
    if not j or j.get('status')!='done':return 'PDF is not ready.',404
    return send_file(j['output'],as_attachment=True,download_name=j['filename'],mimetype='application/pdf')

if __name__=='__main__': app.run(host='127.0.0.1',port=5000,debug=False)
