import { useEffect, useState, type FormEvent } from 'react';
import type { Session } from '@supabase/supabase-js';
import { mount } from '../Layout';
import { site } from '../lib/site';
import { supabase } from '../lib/supabase';

type Learner = {
  id: string;
  name: string;
  total_xp: number;
  streak: number;
  skills: Record<string, number>;
  discoveries: number;
  gamesThisWeek: number;
  daysThisWeek: number;
};

type LearnerSummary = {
  name: string;
  activities: number;
  practice_days: number;
  total_xp: number;
  discoveries: number;
  skills: Record<string, number>;
};
type Report = {
  id: string;
  week_start: string;
  summary: { week_start: string; week_end: string; learners: LearnerSummary[] };
};

type Family = { learners: Learner[]; reports: Report[]; weeklyEmail: boolean };

const skillOrder = ['Number sense', 'Patterns', 'Evidence', 'Reasoning', 'Memory', 'English'];
const skillColour: Record<string, string> = {
  'Number sense': 'var(--saffron)',
  Patterns: 'var(--coral)',
  Evidence: 'var(--blue)',
  Reasoning: 'var(--plum)',
  Memory: 'var(--plum)',
  English: 'var(--forest)',
};

/** Friendly words for the errors Supabase gives back. */
function explain(error: unknown): string {
  const message = error instanceof Error ? error.message : String(error ?? '');
  if (/invalid login credentials/i.test(message)) return 'That email and password don’t match. Try again, or sign in with a code.';
  if (/email not confirmed/i.test(message)) return 'This email isn’t confirmed yet. Use “Email me a code” to confirm and sign in.';
  if (/signups not allowed|user not found/i.test(message)) return 'No Curio account uses this email. Create one in the Curio app first.';
  if (/expired|invalid.*(otp|token)/i.test(message)) return 'That code is wrong or has expired. Ask for a new one.';
  if (/rate limit|too many/i.test(message)) return 'Too many tries — please wait a minute and try again.';
  if (/fetch|network/i.test(message)) return 'We couldn’t reach Curio. Check your connection and try again.';
  return message || 'Something went wrong. Please try again.';
}

const pct = (v: number) => `${Math.round(Math.max(0, Math.min(1, v)) * 100)}%`;
const niceDate = (iso: string) =>
  new Date(`${iso}T00:00:00`).toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' });

function startOfWeek() {
  const now = new Date();
  const monday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - ((now.getDay() + 6) % 7));
  return monday;
}

async function loadFamily(): Promise<Family> {
  const db = supabase!;
  const [{ data: children, error: childError }, { data: reports, error: reportError }, { data: settings }] =
    await Promise.all([
      db.from('child_profiles').select('id,name,total_xp,streak').order('created_at'),
      db.from('parent_reports').select('id,week_start,summary').order('week_start', { ascending: false }).limit(12),
      db.from('family_settings').select('weekly_email_enabled').maybeSingle(),
    ]);
  if (childError) throw childError;
  if (reportError) throw reportError;
  const ids = (children ?? []).map((c) => c.id as string);
  const since = startOfWeek();
  const [skills, found, played] = ids.length
    ? await Promise.all([
        db.from('skill_progress').select('child_id,skill_key,mastery').in('child_id', ids),
        db.from('unlocked_discoveries').select('child_id').in('child_id', ids),
        db
          .from('activity_completions')
          .select('child_id,completed_at')
          .in('child_id', ids)
          .gte('completed_at', since.toISOString()),
      ])
    : [{ data: [] }, { data: [] }, { data: [] }];
  const learners: Learner[] = (children ?? []).map((c) => {
    const mine = (played.data ?? []).filter((a) => a.child_id === c.id);
    return {
      id: c.id,
      name: c.name,
      total_xp: c.total_xp,
      streak: c.streak,
      skills: Object.fromEntries(
        (skills.data ?? []).filter((s) => s.child_id === c.id).map((s) => [s.skill_key, s.mastery]),
      ),
      discoveries: (found.data ?? []).filter((d) => d.child_id === c.id).length,
      gamesThisWeek: mine.length,
      daysThisWeek: new Set(mine.map((a) => new Date(a.completed_at).toDateString())).size,
    };
  });
  return {
    learners,
    reports: (reports ?? []) as Report[],
    weeklyEmail: Boolean(settings?.weekly_email_enabled),
  };
}

function SignIn() {
  const [mode, setMode] = useState<'password' | 'code'>('password');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [code, setCode] = useState('');
  const [codeSent, setCodeSent] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');

  async function run(action: () => Promise<void>) {
    setBusy(true);
    setError('');
    try {
      await action();
    } catch (e) {
      setError(explain(e));
    } finally {
      setBusy(false);
    }
  }

  function submit(event: FormEvent) {
    event.preventDefault();
    const address = email.trim();
    if (mode === 'password') {
      run(async () => {
        const { error } = await supabase!.auth.signInWithPassword({ email: address, password });
        if (error) throw error;
      });
    } else if (!codeSent) {
      run(async () => {
        const { error } = await supabase!.auth.signInWithOtp({ email: address, options: { shouldCreateUser: false } });
        if (error) throw error;
        setCodeSent(true);
        setInfo(`We emailed a sign-in code to ${address}. It may take a minute to arrive.`);
      });
    } else {
      run(async () => {
        const { error } = await supabase!.auth.verifyOtp({ email: address, token: code.trim(), type: 'email' });
        if (error) throw error;
      });
    }
  }

  return (
    <form className="clay auth" onSubmit={submit} noValidate>
      <div>
        <p className="eyebrow">Family dashboard</p>
        <h1 style={{ fontSize: 34 }}>Welcome back.</h1>
        <p className="soft" style={{ marginTop: 8 }}>
          Sign in with the parent account you use in the Curio app.
        </p>
      </div>
      <div className="well tabs" role="tablist" aria-label="Sign-in method">
        {(['password', 'code'] as const).map((m) => (
          <button
            key={m}
            type="button"
            role="tab"
            aria-selected={mode === m}
            onClick={() => {
              setMode(m);
              setError('');
              setInfo('');
              setCodeSent(false);
            }}
          >
            {m === 'password' ? 'Password' : 'Email me a code'}
          </button>
        ))}
      </div>
      <label>
        Email
        <input
          type="email"
          autoComplete="email"
          required
          value={email}
          disabled={codeSent}
          onChange={(e) => setEmail(e.target.value)}
        />
      </label>
      {mode === 'password' ? (
        <label>
          Password
          <input
            type="password"
            autoComplete="current-password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </label>
      ) : codeSent ? (
        <label>
          Code from your email
          <input
            className="code-input"
            type="text"
            inputMode="numeric"
            autoComplete="one-time-code"
            maxLength={10}
            value={code}
            onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))}
          />
        </label>
      ) : null}
      {info ? (
        <p className="notice" role="status">
          {info}
        </p>
      ) : null}
      {error ? (
        <p className="notice error" role="alert">
          {error}
        </p>
      ) : null}
      <button
        className="button"
        type="submit"
        disabled={busy || !email.trim() || (mode === 'password' ? !password : codeSent && code.length < 6)}
      >
        {busy ? 'Please wait…' : mode === 'password' ? 'Sign in' : codeSent ? 'Sign in with code' : 'Send me a code'}
      </button>
      {mode === 'password' ? (
        <p className="muted" style={{ fontSize: 14 }}>
          Forgot your password?{' '}
          <button type="button" className="link-button" onClick={() => setMode('code')}>
            Sign in with a code instead
          </button>
          , then change it in the app.
        </p>
      ) : codeSent ? (
        <button type="button" className="link-button" onClick={() => setCodeSent(false)}>
          Use a different email or resend the code
        </button>
      ) : null}
      <p className="muted" style={{ fontSize: 14 }}>
        New to Curio? Families sign up in the Curio app.
      </p>
    </form>
  );
}

function LearnerCard({ learner }: { learner: Learner }) {
  const skills = skillOrder.filter((s) => s in learner.skills).concat(
    Object.keys(learner.skills).filter((s) => !skillOrder.includes(s)),
  );
  return (
    <article className="clay report" aria-label={`${learner.name}’s progress`}>
      <div className="report-head">
        <h3>{learner.name}</h3>
        <span className="badge">This week</span>
      </div>
      <p className="soft">
        {learner.gamesThisWeek
          ? `${learner.gamesThisWeek} ${learner.gamesThisWeek === 1 ? 'game' : 'games'} on ${learner.daysThisWeek} ${learner.daysThisWeek === 1 ? 'day' : 'days'} so far this week.`
          : 'No games yet this week — a five-minute one is waiting.'}
      </p>
      <div className="stats">
        <div className="stat">
          <b>{learner.total_xp}</b>
          <span>Total XP</span>
        </div>
        <div className="stat" style={{ ['--accent' as string]: 'var(--coral)' }}>
          <b>{learner.streak}</b>
          <span>Day streak</span>
        </div>
        <div className="stat" style={{ ['--accent' as string]: 'var(--forest)' }}>
          <b>{learner.discoveries}</b>
          <span>Discoveries</span>
        </div>
      </div>
      {skills.length ? (
        skills.map((s) => (
          <div key={s} className="skill">
            <span>{s}</span>
            <span className="bar" role="img" aria-label={`${s} ${pct(learner.skills[s])}`}>
              <i style={{ width: pct(learner.skills[s]), background: skillColour[s] ?? 'var(--forest)' }} />
            </span>
            <span className="muted">{pct(learner.skills[s])}</span>
          </div>
        ))
      ) : (
        <p className="muted">Skill levels appear after the first few games.</p>
      )}
    </article>
  );
}

function ReportCard({ report, open }: { report: Report; open: boolean }) {
  const s = report.summary;
  return (
    <details className="clay" open={open}>
      <summary>
        Week of {niceDate(s.week_start ?? report.week_start)}
        {s.week_end ? ` – ${niceDate(s.week_end)}` : ''}
      </summary>
      {(s.learners ?? []).map((l) => (
        <div key={l.name} style={{ marginTop: 14 }}>
          <p>
            <strong>{l.name}</strong>
            <span className="soft">
              {' '}
              — {l.activities} {l.activities === 1 ? 'activity' : 'activities'} across {l.practice_days}{' '}
              {l.practice_days === 1 ? 'practice day' : 'practice days'} · {l.total_xp} lifetime XP ·{' '}
              {l.discoveries} discoveries
            </span>
          </p>
          {Object.entries(l.skills ?? {}).map(([skill, value]) => (
            <div key={skill} className="skill">
              <span>{skill}</span>
              <span className="bar" role="img" aria-label={`${skill} ${pct(value)}`}>
                <i style={{ width: pct(value), background: skillColour[skill] ?? 'var(--forest)' }} />
              </span>
              <span className="muted">{pct(value)}</span>
            </div>
          ))}
        </div>
      ))}
    </details>
  );
}

function WeeklyEmailToggle({ userId, initial }: { userId: string; initial: boolean }) {
  const [on, setOn] = useState(initial);
  const [error, setError] = useState('');
  async function change(next: boolean) {
    setOn(next);
    setError('');
    const { error } = await supabase!.from('family_settings').update({ weekly_email_enabled: next }).eq('parent_id', userId);
    if (error) {
      setOn(!next);
      setError(explain(error));
    }
  }
  return (
    <section className="clay report">
      <div className="row">
        <div>
          <h3>Weekly email</h3>
          <p className="soft">A short summary of the week, sent to your account email.</p>
        </div>
        <label className="switch" aria-label="Send me the weekly email">
          <input type="checkbox" checked={on} onChange={(e) => change(e.target.checked)} />
          <span />
        </label>
      </div>
      {error ? (
        <p className="notice error" role="alert" style={{ marginTop: 12 }}>
          {error}
        </p>
      ) : null}
    </section>
  );
}

function DeleteFamily({ onDeleted }: { onDeleted: () => void }) {
  const [password, setPassword] = useState('');
  const [sure, setSure] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  async function remove(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError('');
    const { error } = await supabase!.functions.invoke('delete-account', { body: { password } });
    if (error) {
      const status = (error as { context?: Response }).context?.status;
      setError(
        status === 403
          ? 'That password isn’t right, so nothing was deleted.'
          : `We couldn’t delete the account. Please try again, or email ${site.contactEmail}.`,
      );
      setBusy(false);
      return;
    }
    await supabase!.auth.signOut();
    onDeleted();
  }
  return (
    <form id="delete" className="clay report danger-zone" onSubmit={remove}>
      <h3>Delete family account</h3>
      <p className="soft" style={{ margin: '6px 0 14px' }}>
        This permanently deletes your account, every learner’s progress, your preferences and all reports. It
        can’t be undone.
      </p>
      <div className="stack" style={{ gap: 12 }}>
        <label>
          Your password
          <input
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </label>
        <label style={{ display: 'flex', gap: 10, alignItems: 'center', fontWeight: 600 }}>
          <input type="checkbox" checked={sure} onChange={(e) => setSure(e.target.checked)} />
          I understand everything will be deleted
        </label>
        {error ? (
          <p className="notice error" role="alert">
            {error}
          </p>
        ) : null}
        <div>
          <button className="button danger" type="submit" disabled={!password || !sure || busy}>
            {busy ? 'Deleting…' : 'Delete everything'}
          </button>
        </div>
      </div>
    </form>
  );
}

function Dashboard({ session }: { session: Session }) {
  const [family, setFamily] = useState<Family | null>(null);
  const [error, setError] = useState('');
  const [deleted, setDeleted] = useState(false);

  useEffect(() => {
    loadFamily().then(setFamily, (e) => setError(explain(e)));
  }, [session.user.id]);

  if (deleted) {
    return (
      <section className="clay auth">
        <h1 style={{ fontSize: 32 }}>Your account is deleted.</h1>
        <p className="soft">Everything has been removed. Thank you for exploring with Curio.</p>
        <a className="button quiet" href="./index.html">
          Back to home
        </a>
      </section>
    );
  }

  return (
    <>
      <div className="dash-head">
        <div>
          <p className="eyebrow">Family dashboard</p>
          <h1 style={{ fontSize: 'clamp(30px, 5vw, 44px)' }}>Your family’s week.</h1>
          <p className="muted" style={{ marginTop: 6 }}>
            Signed in as {session.user.email}
          </p>
        </div>
        <button className="button quiet small" onClick={() => supabase!.auth.signOut()}>
          Sign out
        </button>
      </div>
      {error ? (
        <p className="notice error" role="alert">
          {error}
        </p>
      ) : !family ? (
        <p className="muted" role="status">
          Loading your family…
        </p>
      ) : (
        <div className="stack">
          {family.learners.length ? (
            <div className="grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))' }}>
              {family.learners.map((l) => (
                <LearnerCard key={l.id} learner={l} />
              ))}
            </div>
          ) : (
            <p className="notice">No learner yet — finish setting up a learner in the Curio app.</p>
          )}
          <section aria-labelledby="reports">
            <h2 id="reports" style={{ margin: '18px 0 14px' }}>
              Weekly reports
            </h2>
            {family.reports.length ? (
              family.reports.map((r, i) => <ReportCard key={r.id} report={r} open={i === 0} />)
            ) : (
              <p className="muted">Your first weekly report appears after a week of play.</p>
            )}
          </section>
          <WeeklyEmailToggle userId={session.user.id} initial={family.weeklyEmail} />
          <p className="muted" style={{ fontSize: 14 }}>
            Mastery reflects practice, not a formal assessment.
          </p>
          <DeleteFamily onDeleted={() => setDeleted(true)} />
        </div>
      )}
    </>
  );
}

function Family() {
  const [session, setSession] = useState<Session | null | undefined>(undefined);

  useEffect(() => {
    if (!supabase) return;
    supabase.auth.getSession().then(({ data }) => setSession(data.session));
    const { data } = supabase.auth.onAuthStateChange((_event, next) => setSession(next));
    return () => data.subscription.unsubscribe();
  }, []);

  if (!supabase) {
    return (
      <p className="notice error" role="alert">
        The family dashboard isn’t configured yet (missing Supabase settings).
      </p>
    );
  }
  if (session === undefined) {
    return (
      <p className="muted" role="status">
        Loading…
      </p>
    );
  }
  return session ? <Dashboard session={session} /> : <SignIn />;
}

mount('family', <Family />);
