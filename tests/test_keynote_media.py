import contextlib
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile
import uuid

from runtime import keynote_media as media


class MediaTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.deck = self.root / 'source.key'
        with zipfile.ZipFile(self.deck, 'w') as z:
            z.writestr('Index/Slide.iwa', b'native-text-and-notes')
            z.writestr('Data/old.mp4', b'old-movie')
        self.movie = self.root / 'new movie.mp4'
        self.movie.write_bytes(b'new-encoded-movie')
        self.rows = media.normalize_replacements([
            {'slide': 2, 'movie': self.movie.name, 'duration': 10, 'poster': 9}
        ], self.root)

    def test_mapping_rejects_invalid_timing_and_duplicate_slides(self):
        for duration, poster in [(0, 0), (float('nan'), 0), (10, -1), (10, 10), (10, True)]:
            with self.assertRaises(ValueError):
                media.normalize_replacements([{'slide': 1, 'movie': self.movie.name,
                                               'duration': duration, 'poster': poster}], self.root)
        with self.assertRaises(ValueError):
            media.normalize_replacements(self.rows * 2, self.root)
        self.assertEqual(self.rows[0]['movie'], str(self.movie.resolve()))
        self.assertEqual(media.stamp(59.9996), '00:01:00.000')

    def test_review_copy_never_overwrites_a_path(self):
        old = self.deck.read_bytes()
        with self.assertRaises(FileExistsError):
            media.prepare_copy(self.deck, self.deck)
        out = self.root / 'review.key'
        fingerprint = media.prepare_copy(self.deck, out)
        self.assertEqual(fingerprint, media.deck_fingerprint(out))
        self.assertEqual(self.deck.read_bytes(), old)
        out.write_bytes(b'new-user-work')
        with self.assertRaises(FileExistsError):
            media.prepare_copy(self.deck, out)
        self.assertEqual(out.read_bytes(), b'new-user-work')

    def test_embedded_hash_uses_bytes_not_filenames(self):
        with zipfile.ZipFile(self.deck, 'a') as z:
            z.writestr('Data/new movie.mp4', b'wrong-but-same-name')
            z.writestr('Data/movie-999.mp4', self.movie.read_bytes())
        proof = media.embedded_match(self.deck, self.movie)
        self.assertEqual(proof['entry'], 'Data/movie-999.mp4')
        self.movie.write_bytes(b'a-different-render')
        self.assertIsNone(media.embedded_match(self.deck, self.movie))

    def test_package_copy_and_hash(self):
        package = self.root / 'package.key'
        (package / 'Data').mkdir(parents=True)
        (package / 'Data/renamed.mp4').write_bytes(self.movie.read_bytes())
        with self.assertRaisesRegex(ValueError, 'inside the source'):
            media.prepare_copy(package, package / 'nested.key')
        self.assertFalse((package / 'nested.key').exists())
        out = self.root / 'copy.key'
        media.prepare_copy(package, out)
        self.assertEqual(media.embedded_match(out, self.movie)['entry'], 'Data/renamed.mp4')
        self.assertEqual(media.deck_fingerprint(package), media.deck_fingerprint(out))

    def test_plan_has_no_app_or_file_side_effects(self):
        out = self.root / 'review.key'
        with patch.object(media, 'run_osa', side_effect=AssertionError('No native calls in plan mode')):
            with contextlib.redirect_stdout(io.StringIO()) as buf:
                media.main(['--deck', str(self.deck), '--output', str(out), '--slide', '2',
                            '--movie', str(self.movie), '--duration', '10', '--poster', '9'])
        self.assertFalse(out.exists())
        self.assertEqual(json.loads(buf.getvalue())['mode'], 'plan-only')

    def apply_mocks(self, native_change=False, source_change=False, open_modified=False):
        output = self.root / 'review.key'
        snapshot = {'slides': [
            {'notes': 'Opening', 'movies': [], 'transition': {'automaticTransition': False}},
            {'notes': 'Spoken explanation', 'movies': [{'position': [0, 0]}],
             'transition': {'automaticTransition': False}}]}
        calls = []
        def fake_osa(script=None, **kwargs):
            calls.append(script)
            if script == media.OPEN_DOCUMENTS:
                return json.dumps([{'path': str(self.deck), 'name': self.deck.name,
                                    'modified': True}] if open_modified else [])
            if script == media.SNAPSHOT:
                value = json.loads(json.dumps(snapshot))
                if calls.count(media.SNAPSHOT) == 2:
                    if native_change:
                        value['slides'][1]['notes'] = 'Unexpected edit'
                    if source_change:
                        self.deck.write_bytes(b'new saved user edits')
                return json.dumps(value)
            if script is None:
                self.assertEqual(Path(kwargs['args'][0]), output.resolve())
                with zipfile.ZipFile(output, 'a') as z:
                    z.writestr('Data/new.mp4', self.movie.read_bytes())
                return 'autoplay=true; manual-advance=true; geometry-preserved=true'
            return 'owned-document-id'
        stack = contextlib.ExitStack()
        stack.enter_context(patch.object(media.platform, 'system', return_value='Darwin'))
        stack.enter_context(patch.object(media.shutil, 'which', return_value='/mock/tool'))
        stack.enter_context(patch.object(media, 'run_osa', side_effect=fake_osa))
        stack.enter_context(patch.object(media, 'probe_movie', return_value={
            'duration': 10, 'width': 3840, 'height': 2160, 'fps': 60}))
        return stack, output

    def test_copy_only_apply_verifies_preservation_and_embedded_media(self):
        original = self.deck.read_bytes()
        stack, output = self.apply_mocks()
        with stack:
            result = media.apply_replacements(self.deck, output, self.rows)
        self.assertEqual(result['status'], 'verified-review-copy')
        self.assertTrue(result['native_content_unchanged'])
        self.assertEqual(self.deck.read_bytes(), original)
        self.assertEqual(result['replacements'][0]['embedded']['sha256'], media.sha256(self.movie))

    def test_native_content_change_retains_copy_without_claiming_success(self):
        original = self.deck.read_bytes()
        stack, output = self.apply_mocks(native_change=True)
        with stack, self.assertRaisesRegex(media.KeynoteError, 'Native text'):
            media.apply_replacements(self.deck, output, self.rows)
        self.assertEqual(self.deck.read_bytes(), original)
        self.assertTrue(output.exists())
        self.assertEqual(json.loads(output.with_suffix('.media-review.json').read_text())['status'], 'needs-review')

    def test_new_source_edits_are_never_overwritten(self):
        stack, output = self.apply_mocks(source_change=True)
        with stack, self.assertRaisesRegex(media.KeynoteError, 'Source changed'):
            media.apply_replacements(self.deck, output, self.rows)
        self.assertEqual(self.deck.read_bytes(), b'new saved user edits')
        self.assertTrue(output.exists())

    def test_unsaved_source_stops_before_copy_or_native_mutation(self):
        stack, output = self.apply_mocks(open_modified=True)
        with stack, self.assertRaisesRegex(media.KeynoteError, 'unsaved native edits'):
            media.apply_replacements(self.deck, output, self.rows)
        self.assertFalse(output.exists())


@unittest.skipUnless(os.environ.get('SLIDE_STUDIO_KEYNOTE_MEDIA_SMOKE') == '1',
                     'Opt-in native GUI test; creates only disposable decks under build/')
class NativeMediaSmokeTests(unittest.TestCase):
    def test_native_replacement_preserves_content_and_full_duration(self):
        # This catches native coercion, image-property, modal and selection behavior
        # that mocked AppleEvents cannot exercise. Never pass a user's deck here.
        from runtime import keynote
        root = Path(__file__).resolve().parents[1]
        token = uuid.uuid4().hex[:8]
        work = root / 'build/keynote/media-smoke' / token
        work.mkdir(parents=True)
        source, output = work / f'source-{token}.key', work / f'review-{token}.key'
        original = root / 'scenes/video-budget/demo/movie.mp4'
        replacement = root / 'scenes/branch-and-merge/demo/movie.mp4'
        if not original.is_file() or not replacement.is_file():
            self.skipTest('Generate bundled scene movies before native smoke testing')
        theme = json.loads((root / 'templates/themes/anthony-dark.json').read_text())
        slide = {'id': 'native-media-smoke', 'width': 1920, 'height': 1080,
                 'background': '#2B2B2D',
                 'items': [{'type': 'text', 'text': 'Preserve native content',
                            'x': 100, 'y': 80, 'w': 1720, 'h': 110,
                            'size': 72, 'bold': True, 'color': '#F6F6F4'}],
                 'notes': 'The **movie changes**, while these notes stay the same.',
                 'movie': {'path': str(original), 'x': 320, 'y': 240,
                           'w': 1280, 'h': 720, 'autoplay': True}}
        keynote.assemble(work, source, [slide], theme)
        before = media.deck_fingerprint(source)
        duration = media.probe_movie(replacement)['duration']
        rows = media.normalize_replacements([{'slide': 1, 'movie': str(replacement),
                                              'duration': duration, 'poster': duration - 2}], root)
        report = media.apply_replacements(source, output, rows)
        self.assertEqual(report['status'], 'verified-review-copy')
        self.assertEqual(media.deck_fingerprint(source), before)
        self.assertTrue(report['native_content_unchanged'])
        self.assertTrue(report['closed_after_save'])
        self.assertEqual(report['replacements'][0]['embedded']['sha256'], media.sha256(replacement))
        for expected in ('trim=full', 'autoplay=true', 'manual-advance=true'):
            self.assertIn(expected, report['replacements'][0]['native_flags'])


if __name__ == '__main__':
    unittest.main()
