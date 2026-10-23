export type LearnerSummary = { name: string; activities: number; practice_days: number; total_xp: number; discoveries: number; skills: Record<string, number> };
export type WeeklySummary = { week_start: string; week_end: string; learners: LearnerSummary[] };
export function escapeHtml(value: unknown): string {
  return String(value).replace(/[&<>"']/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]!));
}
export function renderReport(summary: WeeklySummary, appUrl: string) {
  const title = `Your Curio week · ${summary.week_start}`;
  const text = [`Your Curio week: ${summary.week_start} – ${summary.week_end}`, ...summary.learners.map(l => `${l.name}: ${l.activities} activities across ${l.practice_days} practice days. ${l.total_xp} lifetime XP, ${l.discoveries} discoveries collected.\nSkills: ${Object.entries(l.skills).map(([skill, value]) => `${skill}: ${Math.round(value * 100)}%`).join(' · ') || 'Your first practice will start the skill snapshot.'}`), 'Ask your explorer: What surprised you this week?', `Manage or turn off weekly emails in Parent dashboard → Family preferences: ${appUrl}`, 'Mastery reflects practice, not a formal assessment.'].join('\n\n');
  const cards = summary.learners.map(l => `<section style="background:#fff;padding:24px;border-radius:20px;margin:20px 0"><h2>${escapeHtml(l.name)}</h2><p style="font-size:20px">${l.activities} activities · ${l.practice_days} practice days</p><p>${l.total_xp} lifetime XP · ${l.discoveries} discoveries collected</p><p>${Object.entries(l.skills).map(([skill,value])=>`${escapeHtml(skill)}: ${Math.round(value*100)}%`).join(' · ')}</p></section>`).join('');
  const html = `<main style="font-family:Arial,sans-serif;background:#fff8ee;color:#2e2417;max-width:600px;margin:auto;padding:32px;border-radius:24px"><p style="color:#15803f;font-weight:bold">CURIO · LITTLE DISCOVERIES</p><h1>A week of curious thinking.</h1><p>${escapeHtml(summary.week_start)} – ${escapeHtml(summary.week_end)}</p>${cards}<p>Ask your explorer: “What surprised you this week?”</p><p><a href="${escapeHtml(appUrl)}" style="color:#9d3029">Open your family dashboard</a></p><p style="font-size:12px">You opted in to parent reports. Turn off weekly emails anytime in Parent dashboard → Family preferences. Mastery reflects practice, not a formal assessment.</p></main>`;
  return {subject: title, text, html};
}
