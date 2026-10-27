import { mount } from '../Layout';
import { sections, site } from '../lib/site';

const emoji: Record<string, string> = {
  Maths: '🔢',
  Memory: '🧠',
  English: '📖',
  Logic: '🧩',
};

const faqs: [string, string][] = [
  [
    'What does my child need to sign up?',
    'Nothing. A parent or guardian creates the account with their own email, and the learner only ever needs a nickname.',
  ],
  [
    'How long does it take each day?',
    'Each game takes about five minutes. You choose a daily goal of one to four games, and replays are just for practice.',
  ],
  [
    'Are there ads, chats or in-game purchases?',
    'No ads, no chat, no public profiles and no way for children to contact anyone. We never sell or share your family’s data.',
  ],
  [
    'How do weekly reports work?',
    'Turn on weekly emails in the app under Parent dashboard → Family preferences. You can also sign in here at any time to see your learner’s progress and every past report.',
  ],
  [
    'How do I delete our account?',
    'From the app (Profile → Privacy and account), from your family dashboard on this site, or by emailing us. Everything is removed straight away.',
  ],
];

function Home() {
  return (
    <>
      <section className="hero">
        <div>
          <p className="eyebrow">Five-minute brain games</p>
          <h1>Turn “why?” into a daily adventure.</h1>
          <p className="lead">
            Curio gives curious kids one little game a day in Maths, Memory, English and Logic — and gives
            grown-ups a calm, clear view of how they’re growing.
          </p>
          <div className="actions">
            {site.playStoreUrl ? (
              <a className="button" href={site.playStoreUrl}>
                Get it on Google Play
              </a>
            ) : null}
            <a className={site.playStoreUrl ? 'button quiet' : 'button'} href="./family.html">
              Parent login
            </a>
            <a className="button quiet" href="#how">
              How it works
            </a>
          </div>
        </div>
        <div className="hero-art" aria-hidden="true">
          {sections.map((s) => (
            <div key={s.name} className="clay hero-tile tint" style={{ ['--accent' as string]: s.colour }}>
              <span>{emoji[s.name]}</span>
              <b>{s.name}</b>
            </div>
          ))}
        </div>
      </section>

      <section className="section" aria-labelledby="sections">
        <div className="section-head">
          <p className="eyebrow">Four daily sections</p>
          <h2 id="sections">A fresh game in each, every day.</h2>
          <p>Games rotate daily, so there’s always something new — and every one builds a real skill.</p>
        </div>
        <div className="grid">
          {sections.map((s) => (
            <article key={s.name} className="clay card" style={{ ['--accent' as string]: s.colour }}>
              <h3>
                <span className="dot" />
                {s.name}
              </h3>
              <p className="soft">{s.blurb}</p>
              <ul className="chips" aria-label={`${s.name} games`}>
                {s.games.map((g) => (
                  <li key={g} className="chip">
                    {g}
                  </li>
                ))}
              </ul>
            </article>
          ))}
        </div>
      </section>

      <section className="section" id="how" aria-labelledby="how-title">
        <div className="section-head">
          <p className="eyebrow">How it works</p>
          <h2 id="how-title">Little steps that add up.</h2>
        </div>
        <div className="grid">
          {[
            ['01', 'Play for five minutes', 'Pick a daily game in any section. Each one takes about five minutes.'],
            ['02', 'Unlock a discovery', 'Daily play earns points, badges and surprising facts to collect.'],
            ['03', 'Watch skills grow', 'Streaks, skill levels and weekly reports show the progress adding up.'],
          ].map(([n, title, body]) => (
            <article key={n} className="clay card">
              <p className="step-number">{n}</p>
              <h3>{title}</h3>
              <p className="soft">{body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="section split" aria-labelledby="parents">
        <div>
          <p className="eyebrow">For grown-ups</p>
          <h2 id="parents">See the week at a glance.</h2>
          <ul className="ticks">
            <li>A weekly report by email, only if you turn it on</li>
            <li>Every past report and live progress in your family dashboard</li>
            <li>A nickname is all we ever ask about your child</li>
            <li>No ads, no chat, nothing sold — and delete everything anytime</li>
          </ul>
          <a className="button" href="./family.html">
            Open your family dashboard
          </a>
        </div>
        <article className="clay report" aria-label="An example weekly report">
          <div className="report-head">
            <h3>Your Curio week</h3>
            <span className="badge">Example</span>
          </div>
          <p className="soft">Maya practised on 4 days this week.</p>
          <div className="stats">
            <div className="stat">
              <b>9</b>
              <span>Games played</span>
            </div>
            <div className="stat" style={{ ['--accent' as string]: 'var(--plum)' }}>
              <b>720</b>
              <span>Total XP</span>
            </div>
            <div className="stat" style={{ ['--accent' as string]: 'var(--forest)' }}>
              <b>8</b>
              <span>Discoveries</span>
            </div>
          </div>
          {[
            ['Memory', 0.62],
            ['English', 0.48],
            ['Reasoning', 0.35],
          ].map(([skill, value]) => (
            <div key={skill as string} className="skill">
              <span>{skill}</span>
              <span className="bar">
                <i style={{ width: `${(value as number) * 100}%` }} />
              </span>
              <span className="muted">{Math.round((value as number) * 100)}%</span>
            </div>
          ))}
        </article>
      </section>

      <section className="section" aria-labelledby="faq">
        <div className="section-head">
          <p className="eyebrow">Questions</p>
          <h2 id="faq">Good to know.</h2>
        </div>
        {faqs.map(([q, a]) => (
          <details key={q} className="clay">
            <summary>{q}</summary>
            <p>{a}</p>
          </details>
        ))}
        <p className="soft" style={{ marginTop: 22 }}>
          Anything else? Email <a href={`mailto:${site.contactEmail}`}>{site.contactEmail}</a>.
        </p>
      </section>
    </>
  );
}

mount('home', <Home />);
