import re,sys,os,hashlib,json,glob
R='/Users/andrew/vscode_projects/poke-survivor'
S=sys.argv[1]
def strip_comment(l):
    out=[];q=None;i=0
    while i<len(l):
        c=l[i]
        if q:
            if c=='\\': out.append(c+l[i+1:i+2]); i+=2; continue
            if c==q: q=None
        elif c in '"\'': q=c
        elif c=='#': break
        out.append(c); i+=1
    return ''.join(out)
def norm_lines(txt):
    r=[]
    for l in txt.split('\n'):
        l=strip_comment(l).rstrip()
        if not l.strip(): continue
        ind=len(l)-len(l.lstrip('\t '))>0
        l=re.sub(r'\s+',' ',l.strip())
        l=re.sub(r' ?([,:=()\[\]{}+\-*/<>]) ?',r'\1',l)
        r.append(('\x01' if ind else '')+l)
    return r
decl=re.compile(r'^(?:@\w+(?:\([^)]*\))?\s*)*(?:static\s+)?(func|const|var|signal|enum|class)\s+(\w+)')
def index(path):
    if not os.path.exists(path): return None
    txt=open(path,encoding='utf8',errors='replace').read()
    lines=norm_lines(txt)
    syms={};cur='<head>';buf=[]
    def flush():
        if buf: syms.setdefault(cur,[]).extend(buf)
    for l in lines:
        if not l.startswith('\x01'):
            m=decl.match(l)
            if m:
                flush();buf=[];cur=m.group(1)+' '+m.group(2)
        buf.append(l)
    flush()
    return {k:hashlib.md5('\n'.join(v).encode()).hexdigest()[:10] for k,v in syms.items()}
files=set()
for base in (R+'/scripts',S+'/v4src/scripts',R+'/docs/upstream_v51/scripts'):
    for f in glob.glob(base+'/**/*.gd',recursive=True): files.add(os.path.relpath(f,base))
rows=[];detail={}
for f in sorted(files):
    v4=index(S+'/v4src/scripts/'+f);v5=index(R+'/docs/upstream_v51/scripts/'+f);us=index(R+'/scripts/'+f)
    if v5 is None:
        continue
    if v4 is None:
        rows.append((f,'NEW_FILE' if us is None else 'NEW_BOTH',0,0,0,0,len(v5)));continue
    clean=[];conf=[];new=[];same=0
    for k,h in v5.items():
        if v4.get(k)==h: same+=1;continue
        if k not in v4: new.append(k);continue
        if us is None or us.get(k)==v4[k]: clean.append(k)
        else: conf.append(k)
    rem=[k for k in v4 if k not in v5]
    detail[f]=dict(clean=clean,conf=conf,new=new,removed=rem)
    if not(clean or conf or new or rem): continue
    rows.append((f,'DELTA',len(clean),len(conf),len(new),len(rem),len(v5)))
json.dump(detail,open(S+'/detail.json','w'),ensure_ascii=False,indent=0)
for r in rows: print(*r,sep='\t')
