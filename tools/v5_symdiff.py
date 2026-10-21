#!/usr/bin/env python3
"""v5_symdiff.py <v4dir> <файл> <символ> [ours|v5]: unified diff нормализованных тел V4→V5 (или V4→наше)."""
import sys,difflib,re
sys.argv_s=sys.argv
src=open(__file__.replace('v5_symdiff','v5_index')).read().split("files=set()")[0].replace("S=sys.argv[1]","S=''")
exec(src)
v4dir,rel,sym=sys.argv_s[1:4];who=sys.argv_s[4] if len(sys.argv_s)>4 else 'v5'
def body(path):
    txt=open(path,encoding='utf8',errors='replace').read()
    lines=norm_lines(txt);cur=None;out=[]
    for l in lines:
        if not l.startswith('\x01'):
            m=decl.match(l)
            if m: cur=m.group(1)+' '+m.group(2)
        if cur==sym: out.append(l.replace('\x01','\t'))
    return out
a=body(f'{v4dir}/scripts/{rel}')
b=body(f'{R}/docs/upstream_v51/scripts/{rel}' if who=='v5' else f'{R}/scripts/{rel}') if who!='v5' else body(f'{R}/docs/upstream_v51/scripts/{rel}')
if who=='ours': b=body(f'{R}/{"scripts/"+rel}')
sys.stdout.write('\n'.join(difflib.unified_diff(a,b,'V4',who,lineterm='',n=1))+'\n')
