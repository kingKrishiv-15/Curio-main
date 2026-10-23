import { test } from 'node:test';
import assert from 'node:assert/strict';
import { renderReport } from './reports.ts';

test('weekly emails include every learner and all skill progress in both versions', () => {
  const report = renderReport({week_start:'2026-10-12', week_end:'2026-10-18', learners:[
    {name:'Alex', activities:9, practice_days:3, total_xp:720, discoveries:8, skills:{Memory:.42, English:.35, 'Number sense':.5}},
    {name:'Maya', activities:6, practice_days:2, total_xp:480, discoveries:5, skills:{Memory:.2, English:.6}},
  ]}, 'https://curio.example.com');
  for (const content of [report.text, report.html]) {
    for (const expected of ['Alex', 'Maya', '720 lifetime XP', '480 lifetime XP', '42%', '35%', '60%', '2026-10-12', '2026-10-18']) {
      assert.ok(content.includes(expected), `missing ${expected}`);
    }
    assert.match(content, /turn off weekly emails/i);
    assert.match(content, /not a formal assessment/);
  }
});

test('learner-controlled names and skill keys cannot inject markup', () => {
  const report = renderReport({week_start:'2026-10-12', week_end:'2026-10-18', learners:[
    {name:'<img src=x onerror=alert(1)>', activities:1, practice_days:1, total_xp:80, discoveries:1, skills:{'<script>bad</script>':.1}},
  ]}, 'https://curio.example.com');
  assert.ok(!report.html.includes('<img'));
  assert.ok(!report.html.includes('<script>'));
  assert.ok(report.html.includes('&lt;img'));
});
