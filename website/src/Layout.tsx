import type { ReactNode } from 'react';
import { createRoot } from 'react-dom/client';
import { site } from './lib/site';
import './styles.css';

type Page = 'home' | 'family' | 'privacy' | 'delete';

const links: [Page, string, string][] = [
  ['home', 'Home', './index.html'],
  ['privacy', 'Privacy', './privacy.html'],
  ['delete', 'Delete account', './delete-account.html'],
];

export function Layout({ page, children }: { page: Page; children: ReactNode }) {
  return (
    <>
      <a className="skip" href="#main">
        Skip to content
      </a>
      <header className="topbar">
        <a className="brand" href="./index.html" aria-label="Curio home">
          <img src="./curio-mark.svg" alt="" width="40" height="40" />
          <span>curio</span>
        </a>
        <nav aria-label="Main">
          {links.map(([id, label, href]) => (
            <a key={id} href={href} aria-current={page === id ? 'page' : undefined}>
              {label}
            </a>
          ))}
          <a className="button small" href="./family.html" aria-current={page === 'family' ? 'page' : undefined}>
            Parent login
          </a>
        </nav>
      </header>
      <main id="main">{children}</main>
      <footer className="footer">
        <p className="footer-brand">Curio — little discoveries, lifelong curiosity.</p>
        <p>
          <a href="./privacy.html">Privacy Policy</a> · <a href="./delete-account.html">Delete your account</a> ·{' '}
          <a href={`mailto:${site.contactEmail}`}>{site.contactEmail}</a>
        </p>
        <p className="muted">© {new Date().getFullYear()} Curio · developed by {site.developer}</p>
      </footer>
    </>
  );
}

/** Mounts a page into #root. */
export function mount(page: Page, content: ReactNode) {
  createRoot(document.getElementById('root')!).render(<Layout page={page}>{content}</Layout>);
}
