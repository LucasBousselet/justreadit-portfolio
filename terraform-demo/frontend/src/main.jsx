import { render } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import { fetchFeaturedBook, getDummyEbookDownloadUrl } from './api.js';
import './styles.css';

function App() {
  const [book, setBook] = useState(null);
  const [status, setStatus] = useState('Loading demo data...');
  const [error, setError] = useState('');
  const [isDownloading, setIsDownloading] = useState(false);

  useEffect(() => {
    let isMounted = true;

    fetchFeaturedBook()
      .then((data) => {
        if (!isMounted) return;
        setBook(data);
        setStatus('Demo data loaded');
      })
      .catch((err) => {
        if (!isMounted) return;
        setError(err.message || 'Something went wrong while fetching demo data.');
        setStatus('Could not load demo data');
      });

    return () => {
      isMounted = false;
    };
  }, []);

  async function handleDownload() {
    if (!book) return;

    setIsDownloading(true);
    setError('');

    try {
      const downloadUrl = await getDummyEbookDownloadUrl(book.id);
      window.location.assign(downloadUrl);
    } catch (err) {
      setError(err.message || 'Could not start the download.');
    } finally {
      setIsDownloading(false);
    }
  }

  return (
    <main className="page-shell">
      <section className="hero">
        <div className="hero-copy">
          <p className="eyebrow">JustReadIt demo SPA</p>
          <h1>A tiny reader app for your AWS portfolio project.</h1>
          <p className="intro">
            This frontend is intentionally simple: it fetches one demo book record, displays a cover, and starts a dummy e-book download.
          </p>
          <div className="status-card" aria-live="polite">
            <span className="status-dot" />
            <span>{status}</span>
          </div>
        </div>

        <BookCard
          book={book}
          error={error}
          isDownloading={isDownloading}
          onDownload={handleDownload}
        />
      </section>

      <section className="architecture-note">
        <h2>What this demonstrates</h2>
        <div className="note-grid">
          <Note title="RDS-backed API data" body="The featured book can come from your ECS backend, which reads from Postgres/RDS." />
          <Note title="Public image delivery" body="The cover image can later be served from S3 through CloudFront." />
          <Note title="Private e-book download" body="The download button is ready for a backend endpoint that returns a short-lived S3 pre-signed URL." />
        </div>
      </section>
    </main>
  );
}

function BookCard({ book, error, isDownloading, onDownload }) {
  if (error && !book) {
    return (
      <aside className="book-card error-card">
        <h2>Demo data unavailable</h2>
        <p>{error}</p>
      </aside>
    );
  }

  if (!book) {
    return (
      <aside className="book-card loading-card">
        <div className="cover-placeholder" />
        <div className="skeleton title" />
        <div className="skeleton line" />
        <div className="skeleton line short" />
      </aside>
    );
  }

  return (
    <aside className="book-card">
      <img className="book-cover" src={book.coverUrl} alt={`Cover for ${book.title}`} />
      <div className="book-content">
        <p className="book-label">Featured demo book</p>
        <h2>{book.title}</h2>
        <p className="author">by {getAuthorName(book)}</p>
        <p className="description">{book.description}</p>
        <dl className="metadata">
          <div>
            <dt>Year</dt>
            <dd>{book.publishedYear}</dd>
          </div>
          <div>
            <dt>Pages</dt>
            <dd>{book.pages}</dd>
          </div>
        </dl>
        <button className="download-button" type="button" onClick={onDownload} disabled={isDownloading}>
          {isDownloading ? 'Preparing download...' : 'Download dummy e-book'}
        </button>
        {error && <p className="inline-error">{error}</p>}
      </div>
    </aside>
  );
}

function getAuthorName(book) {
  if (!book.author) {
    return 'Unknown author';
  }

  return typeof book.author === 'string' ? book.author : book.author.name;
}

function Note({ title, body }) {
  return (
    <article className="note-card">
      <h3>{title}</h3>
      <p>{body}</p>
    </article>
  );
}

render(<App />, document.getElementById('app'));
