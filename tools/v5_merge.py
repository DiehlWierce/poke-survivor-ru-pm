#!/usr/bin/env python3
"""Трёхсторонняя склейка символа: применяет дельту V4→V5.1 к нашему символу. v5_merge.py <v4dir> <rel> <sym>... ; нераспознанные куски печатает как КОНФЛИКТ."""
import sys,re,difflib,os
args=sys.argv[1:]
src=open(__file__.replace('v5_merge','v5_index')).read().split("files=set()")[0].replace("S=sys.argv[1]","S=''")
exec(src)
v4dir,rel,syms=args[0],args[1],args[2:]
def items(path):
    out=[];cur=None;res={}
    for raw in open(path,encoding='utf8',errors='replace').read().split('\n'):
        c=strip_comment(raw).rstrip()
        if not c.strip(): key=None
        else:
            d=len(c)-len(c.lstrip('\t'))
            n=re.sub(r'\s+',' ',c.strip());n=re.sub(r' ?([,:=()\[\]{}+\-*/<>]) ?',r'\1',n)
            n=re.sub(r"_abn\(\"(\w+)\"\)",r"abx.\1",n)
            key=(d,n)
        m=decl.match(raw) if raw and raw[0] not in ' \t#' else None
        if m: cur=m.group(1)+' '+m.group(2)
        res.setdefault(cur,[]).append((key,raw))
    return res
def find(K,seg,start=0):
    n=len(seg)
    for i in range(start,len(K)-n+1):
        if K[i:i+n]==seg: return i
    return -1
V4=items(f'{v4dir}/scripts/{rel}');V5=items(os.path.join(os.environ.get('V5ROOT',R+'/docs/upstream_v51'),'scripts',rel))
path=f'{R}/scripts/{rel}';txt=open(path,encoding='utf8').read().split('\n')
OURS=items(path)
# пересборка файла по символам
order=[];seen=set()
for raw_sym in OURS:
    order.append(raw_sym)
newsym={}
bad=0
for sym in syms:
    if sym not in V4 or sym not in V5 or sym not in OURS: print('нет символа',sym);bad+=1;continue
    a=[k for k,_ in V4[sym] if k];b5=V5[sym];b=[k for k,_ in b5 if k]
    # raw V5 lines по ключам
    braw=[(k,r) for k,r in b5 if k]
    o=OURS[sym];ik=[(i,k) for i,(k,_) in enumerate(o) if k]
    K=[k for _,k in ik]
    ops=[x for x in difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes() if x[0]!='equal']
    edits=[];ok=True;pos=0
    for tag,i1,i2,j1,j2 in ops:
        new=[r for _,r in braw[j1:j2]]
        if i2>i1:
            p=find(K,a[i1:i2],0)
            if p<0: print(f'КОНФЛИКТ {sym}: не найден старый кусок {a[i1:min(i2,i1+2)]}...');ok=False;continue
            s,e=ik[p][0],ik[p+(i2-i1)-1][0]+1
            edits.append((s,e,new))
        else:
            ctx=a[max(0,i1-2):i1]
            if ctx:
                p=find(K,ctx,0)
                if p<0:
                    ctx=a[max(0,i1-1):i1];p=find(K,ctx,0)
                if p<0: print(f'КОНФЛИКТ {sym}: не найден якорь {a[max(0,i1-2):i1]}');ok=False;continue
                s=ik[p+len(ctx)-1][0]+1
            else:
                s=ik[0][0]
            edits.append((s,s,new))

    new_fix=lambda L:[re.sub(r"_abn\(\"(\w+)\"\)",r"abx.\1",x) for x in L]
    edits=[(s,e,new_fix(n)) for s,e,n in edits]
    lines=[r for _,r in o]
    for s,e,new in sorted(edits,key=lambda x:(x[0],x[1]),reverse=True):
        lines[s:e]=new
    newsym[sym]=lines
    print(('ok ' if ok else 'ЧАСТИЧНО ')+sym,len(edits))
# запись: заменяем в файле тела символов
out=[]
cur_syms=list(OURS.keys())
for sym in cur_syms:
    out+= newsym[sym] if sym in newsym else [r for _,r in OURS[sym]]
open(path,'w',encoding='utf8').write('\n'.join(out))
