import tempfile
import unittest
from pathlib import Path
from runtime import keynote
from runtime.keynote_helpers import primitives

class KeynoteTests(unittest.TestCase):
    def test_unicode_notes_ranges(self):
        plain, ranges = keynote.parse_notes('Hello 🌍. **Bold** after emoji.')
        self.assertEqual(plain, 'Hello 🌍. Bold after emoji.')
        self.assertEqual(ranges, [(10,13)])
        self.assertEqual(plain[ranges[0][0]-1:ranges[0][1]], 'Bold')

    def test_unmatched_emphasis_does_not_silently_change_script(self):
        with self.assertRaises(ValueError):
            keynote.parse_notes('A **broken note')

    def test_escape_applescript_as_data(self):
        self.assertEqual(keynote._q('a"b\\c\nd'), '"a\\"b\\\\c\\nd"')

    def test_output_boundary(self):
        with tempfile.TemporaryDirectory() as t:
            with self.assertRaises(ValueError):
                keynote._within(Path(t).parent/'other.key',t)

    def test_color_and_primitives(self):
        self.assertEqual(primitives.rgba('#12345680'),(18,52,86,128))
        with tempfile.TemporaryDirectory() as t:
            p=Path(t)/'arrow.png'
            placement=primitives.render(p,{'type':'line','x':100,'y':50,'w':80,'h':0,'stroke':'#66A7FF','stroke_width':4,'arrow_end':True})
            self.assertTrue(p.read_bytes().startswith(b'\x89PNG'))
            self.assertLess(placement['x'],100)
            self.assertGreater(placement['w'],80)

    def test_notes_native_black_last(self):
        with tempfile.TemporaryDirectory() as t:
            code,plain=keynote._notes_script('s','A **strong** statement.',t,'notes',{})
            self.assertEqual(code[-1],'set color of presenter notes of s to {0,0,0}')
            self.assertTrue(any('to 25' in c for c in code))

if __name__=='__main__':
    unittest.main()
