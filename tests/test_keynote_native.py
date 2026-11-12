"""Opt-in macOS integration check; creates and closes only its own temporary deck.

SLIDE_STUDIO_KEYNOTE_SMOKE=1 python3 -m unittest tests.test_keynote_native
"""
import json
import os
from pathlib import Path
import platform
import subprocess
import tempfile
import unittest
from runtime import keynote
from runtime.keynote_helpers import primitives


@unittest.skipUnless(platform.system()=='Darwin' and os.environ.get('SLIDE_STUDIO_KEYNOTE_SMOKE')=='1',
                     'Opt-in macOS native application test')
class NativeKeynoteTest(unittest.TestCase):
    def test_roundtrip_notes_and_native_media(self):
        studio=Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory(prefix='native-smoke-',dir=studio/'build') as temp:
            p=Path(temp); out=p/'test.key'
            theme=json.loads((studio/'templates/themes/anthony-dark.json').read_text())
            source=p/'portrait-source.png'
            primitives.render(source,{'type':'rect','x':0,'y':0,'w':240,'h':360,'fill':'#66A7FF','stroke':'#7ABC73','stroke_width':20})
            slides=[{'id':'alpha','width':1920,'height':1080,'background':'#2B2B2D',
                     'items':[{'type':'text','text':'Native text remains editable','x':100,'y':90,'w':1720,'h':100,'size':64,'bold':True,'color':'#F6F6F4'},
                              {'type':'image','path':str(source),'x':100,'y':250,'w':250,'h':250,'mask':'circle','focal_x':.5,'focal_y':.35}],
                     'notes':'Hello 🌍. **Bold** after emoji.'},
                    {'id':'beta','width':1920,'height':1080,'background':'#2B2B2D','items':[],
                     'notes':'The next slide has a native movie.',
                     'movie':{'path':str(studio/'scenes/video-budget/demo/movie.mp4'),'x':0,'y':0,'w':1920,'h':1080,'autoplay':True}}]
            report=keynote.assemble(p,out,slides,theme)
            self.assertEqual(report['movie_objects'],1)
            self.assertEqual(report['editable_text_objects'],1)
            self.assertEqual(len(report['warnings']),1)
            self.assertTrue(report['notes_verified'])
            # Move the slides in Keynote. Binding must follow markers, not index.
            code=f'''tell application "Keynote"
set d to open POSIX file {keynote._q(out)}
set boldFont to font of character 10 of presenter notes of slide 1 of d
move slide 2 of d to before slide 1 of d
save d
close d saving yes
return boldFont
end tell'''
            r=subprocess.run(['osascript','-e',code],capture_output=True,text=True)
            self.assertEqual(r.returncode,0,r.stderr)
            self.assertIn('Bold',r.stdout)
            result=keynote.update_notes(p,out,{'alpha':'We give the **short answer** first.'})
            self.assertEqual(result['updated'],1)
            binding=json.loads(out.with_suffix('.bindings.json').read_text())
            self.assertEqual(binding['slides']['alpha']['index'],2)
            # A wrong expected baseline rejects the whole request before edits.
            with self.assertRaises(keynote.NotesConflict):
                keynote.update_notes(p,out,{'alpha':'Do not write this.','beta':'Do not write this either.'},
                                     expected_old={'alpha':'An outdated manual version.'})
            after=json.loads(out.with_suffix('.bindings.json').read_text())
            self.assertEqual(after['slides']['alpha']['notes'],'We give the short answer first.')
            preview=keynote.export_preview(p,out,p/'preview')
            self.assertEqual(len(preview['images']),2)

if __name__=='__main__':
    unittest.main()
