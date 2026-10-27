import { mount } from '../Layout';
import { site } from '../lib/site';

const Mail = () => <a href={`mailto:${site.contactEmail}`}>{site.contactEmail}</a>;

function Privacy() {
  return (
    <article className="clay doc">
      <h1>Privacy Policy</h1>
      <p className="meta">
        Effective date: 27 October 2026 · Applies to the Curio app on Android, iOS and the web, and to this
        website
      </p>
      <p>
        Curio is a learning app of short daily brain games for children, set up and managed by a parent or
        guardian. This policy explains what information Curio collects, why, and the choices you have. We’ve
        written it in plain language because the people reading it are busy parents.
      </p>
      <div className="well">
        <strong>The short version:</strong> a parent creates the account with their email. Children only ever
        need a nickname. We keep game progress so learning can continue across devices. We don’t show ads, we
        don’t sell data, and you can delete everything at any time.
      </div>

      <h2>1. Who is responsible</h2>
      <p>
        Curio is developed by {site.developer} (“we”, “us”). For any privacy question or request, contact us at{' '}
        <Mail />.
      </p>

      <h2>2. Information we collect</h2>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Information</th>
              <th>Whose</th>
              <th>Why we need it</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Email address and password (stored only as a secure hash)</td>
              <td>Parent</td>
              <td>To create the account, sign in, send sign-in and confirmation codes, and reset passwords</td>
            </tr>
            <tr>
              <td>Learner nickname</td>
              <td>Child</td>
              <td>So the app can greet the learner. A nickname is enough — we never ask for a child’s full name</td>
            </tr>
            <tr>
              <td>Learning progress: games completed, points (XP), streaks, discoveries unlocked, skill levels</td>
              <td>Child</td>
              <td>To save progress and show it in the app, the parent view and the family dashboard</td>
            </tr>
            <tr>
              <td>Family preferences: daily goal, reminder time, time zone, weekly email choice</td>
              <td>Parent</td>
              <td>To run reminders and the optional weekly summary the way you chose</td>
            </tr>
            <tr>
              <td>Record of your agreement to this policy (version and date)</td>
              <td>Parent</td>
              <td>To show that a parent or guardian agreed when the account was created</td>
            </tr>
            <tr>
              <td>In-app notifications and weekly reports</td>
              <td>Parent</td>
              <td>To show your inbox and progress summaries</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p>
        We do not collect a child’s full name, photos, voice, contacts, precise location, advertising ID, or any
        payment information. Curio has no chat, no public profiles, and no way for children to contact other
        users.
      </p>
      <p>
        Basic technical data (such as IP address and device type) is processed by our hosting provider when the
        app or this website connects to our servers, as part of normal security and operation. We don’t use it
        to profile anyone. This website uses no advertising or analytics trackers; signing in keeps a session on
        your device only so you stay signed in.
      </p>

      <h2>3. Children’s privacy</h2>
      <ul>
        <li>
          Curio accounts are created and controlled by a parent or guardian, who confirms they are an adult with
          authority to agree for the child before the account is created.
        </li>
        <li>Children are not asked for their email address or any contact details.</li>
        <li>We collect only what is needed for the learning experience (a nickname and progress) and nothing more.</li>
        <li>
          We do not show advertising, use third-party ad or analytics trackers, or sell or share children’s
          information.
        </li>
        <li>A parent can review, export or delete their child’s information at any time (see section 7).</li>
      </ul>
      <p>If you believe a child has created an account without a parent’s involvement, contact us and we will delete it.</p>

      <h2>4. How we use information</h2>
      <ul>
        <li>To provide the app and family dashboard: sign-in, saving progress, syncing across devices.</li>
        <li>
          To send the emails you need or ask for: sign-up and sign-in codes, password resets, and — only if you
          turn it on — a weekly progress summary.
        </li>
        <li>To keep accounts secure and prevent abuse.</li>
      </ul>
      <p>We do not use your information for advertising, and we don’t make automated decisions about you or your child.</p>

      <h2>5. Who we share it with</h2>
      <p>
        We do not sell or rent personal information. We use a small number of service providers who process data
        only on our instructions to run Curio:
      </p>
      <ul>
        <li>
          <strong>Supabase</strong> — database, sign-in and hosting.
        </li>
        <li>
          <strong>Resend</strong> — to deliver codes and the optional weekly email.
        </li>
      </ul>
      <p>We may disclose information if required by law, or to protect the safety of users.</p>

      <h2>6. Security and storage</h2>
      <ul>
        <li>All data is encrypted in transit (HTTPS).</li>
        <li>Passwords are stored as secure hashes; we can never see them.</li>
        <li>
          Each family’s data is isolated: database rules allow a signed-in parent to access only their own
          family’s records.
        </li>
        <li>Your information may be stored on servers outside your country, with our providers’ safeguards in place.</li>
      </ul>

      <h2>7. Your choices and rights</h2>
      <ul>
        <li>
          <strong>See your data:</strong> sign in to the <a href="./family.html">family dashboard</a>, or in the
          app go to Profile → Privacy and account → Export my account data.
        </li>
        <li>Change your learner’s nickname and your family preferences anytime in the app.</li>
        <li>Turn off reminders and the weekly email anytime in Family preferences or the family dashboard.</li>
        <li>
          <strong>Delete your account</strong> and all of your family’s data from the app (Profile → Privacy and
          account → Delete family account), from the family dashboard, or see{' '}
          <a href="./delete-account.html">how to request deletion</a>.
        </li>
      </ul>
      <p>
        Depending on where you live, you may have further rights (for example under the GDPR, India’s DPDP Act or
        COPPA). Contact us to exercise them; we’ll respond within 30 days.
      </p>

      <h2>8. How long we keep data</h2>
      <p>
        We keep your information while your account is active. When you delete your account, your family’s data
        is permanently deleted from our live systems straight away; any copies in routine backups expire within
        30 days.
      </p>

      <h2>9. Changes to this policy</h2>
      <p>
        If we change this policy, we’ll update the date at the top. If a change affects how we use your family’s
        data in a meaningful way, we’ll ask you to agree again in the app.
      </p>

      <h2>10. Contact</h2>
      <p>
        Questions or requests: <Mail />
      </p>
    </article>
  );
}

mount('privacy', <Privacy />);
