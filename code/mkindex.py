#!/usr/bin/env python3
"""Build book-index.html from the headings of every chapter and appendix,
Chapter 3's keyword entries and the registers in Appendix E.

Run from the repository root:  python3 code/mkindex.py
Rerun it after adding, renaming or moving a heading.
"""
import re, glob, html, os, sys
from html.parser import HTMLParser
root = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
class H(HTMLParser):
    def __init__(s):
        super().__init__(); s.hs=[]; s.cur=None
    def handle_starttag(s,t,a):
        if t in ('h1','h2','h3','h4'):
            s.cur=[t,dict(a).get('id'),'']
    def handle_endtag(s,t):
        if s.cur and t==s.cur[0]:
            s.cur[2]=re.sub(r'\s+',' ',s.cur[2]).strip(); s.hs.append(tuple(s.cur)); s.cur=None
    def handle_data(s,d):
        if s.cur: s.cur[2]+=d
GENERIC={'from basic','from basic 1','from machine language','registers','the registers','versions','sizes',
 'memory','origin','flags','examples','what it does','how it works','pointer','strings','sys','sys to','bank',
 'variations','the services','a worked example','memory layout','the basic program','the machine language routine',
 'what each part demonstrates','using the header','building it byte by byte','loading it','playing it',
 'detecting the end','preparing the sound','pitfalls','attributes','stereo','partitions','mounting','speed',
 'conventions','error handling','numbers','input','output','calculations','channel registers','sample rate',
 'mixer registers','inputs and outputs','layout registers','mode registers','hot registers','stability','timing',
 'sizing rows','time limits','using the routines','address formulas','drawing lines','colours','screen codes',
 'control codes','useful values','columns 0 to 7','columns 8 to f','basic programs','machine-language programs',
 'c65 programs','standard entries','extended entries','error codes','tokens','a dma list','the knock',
 'multiplying','dividing','sound','play','colour','sprites','system','functions','statements','expressions',
 'operators','variables','debugging','subroutines','interrupts','files','file types','reading the entries'}
KEEPCAP={'BASIC','MEGA65','Freezer','Hypervisor','Matrix','Mode','Xemu','Ethernet','KERNAL','West','I/O','DMA',
 'C64','C65','C128','SID','SIDs','VIC','CPU','ROM','RAM','SD','IEC','UART','USR','SYS','MAP','GOTOX','PLAY','RRB'}
def sentence(t):
    w=t.split(' ')
    out=[w[0]]
    for x in w[1:]:
        core=x.strip('(),:')
        if core in KEEPCAP or not core[:1].isupper() or (len(core)>1 and not core[1:].islower()):
            out.append(x)
        else:
            out.append(x[0].lower()+x[1:])
    return ' '.join(out)
# Index names that say more than the heading does: link target -> entry.
RENAME={
 'ch12-graphics.html#brightness-first':'Luma (brightness first)',
 'ch12-graphics.html#clipping-at-the-edges':'RRB objects: clipping',
 'ch12-graphics.html#light-is-not-linear':'Gamma (light is not linear)',
 'ch12-graphics.html#mixing-colours':'Dithering and colour mixing',
 'ch12-graphics.html#moving-the-pointer-list':'Moving the sprite pointer list',
 'ch12-graphics.html#one-change-per-frame':'Frame timing for animation',
 'ch12-graphics.html#rows-of-any-length':'Rows of any length (SEAM)',
 'ch12-graphics.html#the-update-in-machine-language':'RRB objects: machine language',
 'ch12-graphics.html#vertical-positioning':'RRB objects: vertical positioning',
 'ch12-graphics.html#what-to-change':'Sprite frames and glyph swapping',
}
# Entries under a second name: (entry, link target, where).
EXTRA=[
 ('Software sprites','ch12-graphics.html#rrb-objects','Chapter 12'),
 ('DMA: texture scaling','ch12-graphics.html#scaling-an-object-with-dma','Chapter 12'),
 ('Alternate palette bank','ch12-graphics.html#several-palettes','Chapter 12'),
]
def lc1(t):
    return t[0].lower()+t[1:] if len(t)>1 and t[1].islower() else t
SKIP=re.compile(r'^(introduction|summary|notes(-\d+)?|contents)$',re.I)
def chapter_label(f, h1):
    m=re.match(r'ch(\d+)-',f)
    return f'Chapter {int(m.group(1))}' if m else None
entries=[]  # (display, sortkey, href, where)
files=sorted(glob.glob(root+'/ch[0-9][0-9]-*.html'))+[root+'/appendices.html']
for path in files:
    f=path.split('/')[-1]
    p=H(); p.feed(open(path).read())
    chap=chapter_label(f,None)
    h2=None; app=None
    for t,i,txt in p.hs:
        if t=='h1' or not i: continue
        where=chap
        if f=='appendices.html':
            if t=='h2':
                m=re.match(r'Appendix ([A-Z]): (.*)',txt); app=m.group(1); where=f'Appendix {app}'
                txt=m.group(2)
            else: where=f'Appendix {app}'
            if app=='J' and t!='h2': continue
        if f.startswith('ch03') and t=='h4' and not re.search('[a-z]',txt):
            for kw in [k.strip() for k in txt.split(',')]:
                entries.append((f'<code>{html.escape(kw)}</code>', kw.lower(), f'{f}#{i}', where))
            continue
        txt=sentence(txt)
        if t=='h2': h2=txt
        if SKIP.match(txt) or txt.lower().startswith('summary'): continue
        disp=txt
        if t in ('h3','h4') and txt.lower() in GENERIC and h2:
            disp=f'{re.sub(r"^(The|A|An) ","",h2)}: {lc1(txt)}'
        elif txt.lower() in GENERIC and t=='h2':
            pass
        disp=re.sub(r'^(The|A|An) ','',disp)
        if not re.match(r'^\w*\d',disp): disp=disp[0].upper()+disp[1:]
        disp=RENAME.get(f'{f}#{i}',disp)
        entries.append((html.escape(disp), disp.lower(), f'{f}#{i}', where))
for d,h,w in EXTRA:
    if h.split('#')[1] in open(root+'/'+h.split('#')[0]).read(): entries.append((html.escape(d), d.lower(), h, w))
# Appendix E registers
s=open(root+'/appendices.html').read()
e=s[s.index('id="appendix-e-key-registers"'):s.index('id="appendix-f-')]
for r in re.findall(r'<tr class="(?:odd|even)">\s*<td>(.*?)</td>\s*<td>(.*?)</td>\s*<td>(.*?)</td>\s*<td>(.*?)</td>',e,re.S):
    addr=re.sub(r'\s+',' ',r[0]); name=re.sub(r'<[^>]+>','',re.sub(r'\s+',' ',r[1]))
    chs=[c.strip() for c in re.sub(r'<[^>]+>','',r[3]).split(',') if c.strip().isdigit()]
    key=re.sub(r'<[^>]+>','',addr)
    entries.append((f'{addr} ({html.escape(name)})', '$'+key.lower(), 'appendices.html#appendix-e-key-registers',
                    'Appendix E'+''.join(f', <a href="{g}">Chapter {c}</a>' for c in chs for g in [sorted(glob.glob(root+f"/ch{int(c):02d}-*.html"))[0].split("/")[-1]])))
# group
def letter(k):
    k=re.sub(r'^[^0-9a-z$]+','',k)
    if k.startswith('$'): return 'Addresses'
    if not k or not k[0].isalpha(): return '0-9'
    return k[0].upper()
def sortkey(k):
    k=re.sub(r'^[^0-9a-z$]+','',k.lower())
    return k
groups={}
seen=set()
for d,k,h,w in entries:
    if (d,h) in seen: continue
    seen.add((d,h)); groups.setdefault(letter(k),[]).append((sortkey(k),d,h,w))
order=['0-9']+[chr(c) for c in range(65,91)]+['Addresses']
keys=[k for k in order if k in groups]
gid=lambda k:'index-'+k.lower()
out=['''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes" />
  <title>Programming the MEGA65 — Index</title>
  <link rel="stylesheet" href="style.css" />
</head>
<body>
<nav class="chapnav"><span></span><a href="index.html">Contents</a><span></span></nav>
<h1 id="index">Index</h1>
<p>Topics, BASIC 65 keywords and registers, with links to the sections
that explain them. BASIC 65 keywords link to their entries in Chapter 3;
registers are listed under Addresses at the end, and link to Appendix E
and the chapters that use them. Technical terms are explained in the <a
href="appendices.html#appendix-j-glossary">Glossary</a>.</p>''',
'<p>'+' · '.join(f'<a href="#{gid(k)}">{k}</a>' for k in keys)+'</p>']
for k in keys:
    out.append(f'<h2 id="{gid(k)}">{k}</h2>\n<ul class="bookindex">')
    for sk,d,h,w in sorted(groups[k], key=lambda x:(x[0],x[3])):
        if w.startswith('Appendix E,') or w=='Appendix E':
            out.append(f'<li><a href="{h}">{d}</a> — {w}</li>')
        else:
            out.append(f'<li><a href="{h}">{d}</a> — {w}</li>')
    out.append('</ul>')
out.append('<nav class="chapnav"><span></span><a href="index.html">Contents</a><span></span></nav>\n</body>\n</html>\n')
open(root+'/book-index.html','w').write('\n'.join(out))
print(sum(len(v) for v in groups.values()), keys)
