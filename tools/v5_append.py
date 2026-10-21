#!/usr/bin/env python3
"""Дописывает в конец нашего файла символы, которых у нас нет, из V5.1: v5_append.py scripts/x.gd "var a" ..."""
import sys
sys.argv_save=sys.argv
src=open(__file__.replace('v5_append','v5_splice')).read().split("rel=sys.argv")[0]
exec(src)
rel,names=sys.argv_save[1],sys.argv_save[2:]
th={k:b for k,b in split(open(__import__('os').path.join(__import__('os').environ.get('V5ROOT',R+'/docs/upstream_v51'),rel),encoding='utf8').read()) if k}
s=open(f'{R}/{rel}',encoding='utf8').read().rstrip('\n')
for n in names: s+='\n\n'+'\n'.join(th[n]).rstrip('\n')
open(f'{R}/{rel}','w',encoding='utf8').write(s+'\n')
