import { mount } from '../Layout';
import { site } from '../lib/site';

function DeleteAccount() {
  const mail = `mailto:${site.contactEmail}?subject=${encodeURIComponent('Delete my Curio account')}`;
  return (
    <article className="clay doc">
      <h1>Delete your Curio account</h1>
      <p className="meta">Curio · developed by {site.developer}</p>
      <p>You can delete your family account and everything in it in any of these three ways.</p>

      <h2>On this website</h2>
      <ol>
        <li>
          Open the <a href="./family.html">family dashboard</a> and sign in.
        </li>
        <li>
          Scroll to <strong>Delete family account</strong>, enter your password and confirm.
        </li>
      </ol>
      <p>Your account is deleted immediately.</p>

      <h2>In the app</h2>
      <ol>
        <li>Open Curio and sign in.</li>
        <li>
          Go to <strong>Profile → Privacy and account</strong>.
        </li>
        <li>
          Tap <strong>Delete family account</strong>, enter your password, and confirm.
        </li>
      </ol>

      <h2>By email</h2>
      <p>
        If you can’t sign in, email <a href={mail}>{site.contactEmail}</a> from the address you signed up with,
        with the subject “Delete my Curio account”. We’ll confirm and delete it within 7 days.
      </p>

      <h2>What gets deleted</h2>
      <ul>
        <li>Your email address and sign-in details</li>
        <li>Your learner’s nickname and all learning progress (games, points, streaks, discoveries, skill levels)</li>
        <li>Family preferences, notifications and weekly reports</li>
      </ul>
      <div className="well">
        Nothing is kept on our live systems. Copies in routine backups expire within 30 days.
      </div>
      <p>
        Read the full <a href="./privacy.html">Privacy Policy</a>.
      </p>
    </article>
  );
}

mount('delete', <DeleteAccount />);
