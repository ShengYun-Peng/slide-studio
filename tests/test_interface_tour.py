import json
import tempfile
import unittest
from pathlib import Path
from runtime.common import ROOT
from runtime.pipeline import scene_config, validate_scene_config, resolve_scene_assets, renderer_for

class InterfaceTourChecks(unittest.TestCase):
    def test_duration_override_retimes_motion_and_fades_without_geometry_changes(self):
        original=scene_config('interface-tour')
        faster=scene_config('interface-tour',{'duration':6})
        for name in ('shots','camera','pointer','captions'):
            for a,b in zip(original['content'][name],faster['content'][name]):
                self.assertEqual(b['time'],a['time']/2)
                for field in ('x','y','w','asset','text'):
                    if field in a:self.assertEqual(b[field],a[field])
                if 'fade' in a:self.assertEqual(b['fade'],a['fade']/2)
        self.assertEqual(faster['content']['assets'],original['content']['assets'])

    def test_state_and_detail_files_are_portable_and_hashed(self):
        cfg=scene_config('interface-tour')
        resolved,hashes=resolve_scene_assets(cfg,ROOT/'scenes/interface-tour')
        self.assertEqual(len(hashes),3)
        self.assertTrue(Path(resolved['content']['assets']['selected']['layers'][0]['file']).is_file())
        self.assertEqual(cfg['content']['assets']['overview']['file'],'overview.png')
        self.assertEqual(renderer_for('interface-tour').name,'interface-tour.swift')

    def test_camera_only_override_keeps_bundled_assets_and_single_file_override_is_local(self):
        with tempfile.TemporaryDirectory() as td:
            directory=Path(td);(directory/'overview.png').write_bytes(b'replacement')
            overrides={'content':{'assets':{'overview':{'file':'overview.png'}}}}
            cfg=scene_config('interface-tour',overrides)
            resolved,hashes=resolve_scene_assets(cfg,directory,ROOT/'scenes/interface-tour',overrides)
            self.assertEqual(resolved['content']['assets']['overview']['file'],str((directory/'overview.png').resolve()))
            self.assertEqual(resolved['content']['assets']['selected']['file'],str(ROOT/'scenes/interface-tour/selected.png'))
            self.assertIn('project:overview.png',hashes)
            self.assertIn('template:selected.png',hashes)

    def test_unknown_states_invalid_camera_and_out_of_order_keys_fail_early(self):
        for mutation in (
            lambda c:c['content']['shots'][1].update(asset='missing'),
            lambda c:c['content']['camera'][1].update(w=0),
            lambda c:c['content']['camera'][1].update(time=0),
            lambda c:c['content']['camera'][1].update(x=float('nan')),
            lambda c:c['content']['assets']['overview'].update(rect=None),
            lambda c:c['content']['assets']['selected'].update(layers=None),
            lambda c:c['content'].update(camera=[None]),
            lambda c:c.update(width=3841),
        ):
            cfg=scene_config('interface-tour');mutation(cfg)
            with self.assertRaises(ValueError):validate_scene_config(cfg)

    def test_nested_asset_cannot_escape_project(self):
        with tempfile.TemporaryDirectory() as td:
            cfg=scene_config('interface-tour');cfg['content']['assets']['overview']['file']='../outside.png'
            with self.assertRaises(ValueError):resolve_scene_assets(cfg,Path(td))

if __name__=='__main__':unittest.main()
