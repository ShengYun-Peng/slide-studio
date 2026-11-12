#!/usr/bin/env python3
"""Rebuild the editable template with the same layout and Keynote adapters.

Run from anywhere: python3 templates/keynote/build_template.py
No existing defense deck or proprietary source asset is required.
"""
from pathlib import Path
import json
import sys

STUDIO = Path(__file__).resolve().parents[2]
sys.path.insert(0,str(STUDIO))
from runtime import keynote, layout


def build():
    theme=json.loads((STUDIO/'templates/themes/anthony-dark.json').read_text())
    specs=[
        dict(id='opening',layout='title',eyebrow='RESEARCH TALK',title='A clear idea.\nEvidence people can trust.',subtitle='Replace this promise with what your audience will learn.',presenter='Your name · Your organization'),
        dict(id='question',layout='question',title='What would make this work\nin practice?',subtitle='A short bridge from the evidence to your next contribution.',part=0),
        dict(id='comparison',layout='comparison',title='Show the difference that matters',columns=[{'title':'The current approach','body':['State the limitation clearly.','Use the same visual scale.']},{'title':'Your contribution','body':['Name the new idea.','Highlight the result that matters.']}]),
        dict(id='roadmap',layout='roadmap',title='One mission, three connected parts',parts=[{'title':'Understand the problem','papers':[{'title':'Discover the pattern','detail':'Measure a phenomenon people missed.'},{'title':'Define the challenge','detail':'Turn the observation into a clear question.'}]},{'title':'Build the solution','papers':[{'title':'Develop the method','detail':'Explain the idea before the details.'}]},{'title':'Scale the impact','papers':[{'title':'Test in practice','detail':'Show where the approach makes a difference.'}]}]),
        dict(id='paper-cover',layout='paper-cover',title='A short, memorable name',subtitle='The full paper title goes here',authors=[{'name':'Your Name','initials':'YN','presenter':True},{'name':'Coauthor One','initials':'CO'},{'name':'Coauthor Two','initials':'CT'}],venue='Conference · Year',part=1),
        dict(id='takeaway',layout='takeaway',title='Three points worth remembering',body=['Discover a phenomenon worth explaining.','Develop a method that addresses the cause.','Show why the result matters in practice.'],part=1),
        dict(id='impact',layout='impact',title='Make the impact easy to see',columns=[{'title':'Scientific impact','body':['A new finding','A reusable method']},{'title':'Practical impact','body':['Verified adoption','A real deployment']},{'title':'Open impact','body':['Reusable resources','Community uptake']}],footer='Replace every claim with a supported fact and a source in your project.'),
        dict(id='acknowledgements',layout='acknowledgements',title='Thank the people behind the work',subtitle='Research is a team effort.',body=['Advisors and committee','Collaborators and labmates','Friends and family'])]
    notes=[
        'Hi, I’m your presenter. By the end of this talk, you’ll know what the new idea is, why it works, and where it can help. Let me start with a familiar problem.',
        'We have seen what goes wrong. So the next question is simple: what would make this work in practice?',
        'Here is the main difference. On the left is the approach we started with. On the right is the idea we developed to address its key limitation.',
        'The talk has three connected parts. First, we understand the problem. Then we build a solution. Finally, we show what changes when people use it.',
        'That question led to this work. I’ll start with the idea, then show the evidence.',
        'To wrap up this work, there are three things to remember. We found a pattern, built a method around it, and tested whether it helps in practice.',
        'The impact goes beyond a single result. This is where we can point to supported evidence of scientific progress, practical use, and community uptake.',
        'I’m grateful to everyone who made this work possible. Thank you for your advice, your collaboration, and your support.'
    ]
    manifests=[]
    for i,(s,n) in enumerate(zip(specs,notes),1):
        m=layout.make_manifest(s,theme,STUDIO,i,len(specs));m['notes']=n;manifests.append(m)
    out=STUDIO/'templates/keynote/anthony-dark-template.key'
    report=keynote.assemble(STUDIO,out,manifests,theme,overwrite=out.exists())
    preview=STUDIO/'build/keynote/template-preview'
    if preview.exists():
        import shutil
        shutil.rmtree(preview)
    export=keynote.export_preview(STUDIO,out,preview)
    (STUDIO/'templates/keynote/template-manifests.json').write_text(json.dumps(manifests,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'assembly':report,'preview':export},indent=2))

if __name__=='__main__':
    build()
