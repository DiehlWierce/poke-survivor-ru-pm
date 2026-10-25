p='docs/upgrade-3.4.0/LEDGER.md';L=open(p).read().split('\n')
out=[];i=0;n=0
while i<len(L):
    if L[i].startswith('<<<<<<<'):
        a=[];b=[];i+=1
        while not L[i].startswith('======='):
            a.append(L[i]);i+=1
        i+=1
        while not L[i].startswith('>>>>>>>'):
            b.append(L[i]);i+=1
        i+=1
        if len(a)==len(b):
            for x,y in zip(a,b):
                out.append(x if not x.rstrip().endswith('| TODO |') else y)
        else:
            out+=a+[y for y in b if y not in a]
        n+=1
    else:
        out.append(L[i]);i+=1
open(p,'w').write('\n'.join(out))
print(n)
