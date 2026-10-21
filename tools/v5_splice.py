#!/usr/bin/env python3
"""Заменяет символы верхнего уровня нашего файла телами из V5.1: v5_splice.py scripts/x.gd "const A" "func b" ..."""
import re,sys
R=__file__.rsplit('/tools/',1)[0]
decl=re.compile(r'^(?:@\w+(?:\([^)]*\))?\s*)*(?:static\s+)?(func|const|var|signal|enum|class)\s+(\w+)')
def split(txt):
    out=[];cur=None;buf=[]
    for l in txt.split('\n'):
        m=decl.match(l)
        if m:
            out.append((cur,buf));cur=m.group(1)+' '+m.group(2);buf=[]
        buf.append(l)
    out.append((cur,buf));return out
rel=sys.argv[1];names=sys.argv[2:]
ours=split(open(f'{R}/{rel}',encoding='utf8').read())
theirs={k:b for k,b in split(open(f'{R}/docs/upstream_v51/{rel[len("scripts/"):] if False else rel}',encoding='utf8').read()) if k}
res=[];done=set()
for k,b in ours:
    if k in names and k in theirs:
        res+=theirs[k];done.add(k)
    else: res+=b
miss=[n for n in names if n not in done]
open(f'{R}/{rel}','w',encoding='utf8').write('\n'.join(res))
print('replaced',sorted(done),'missing',miss)
