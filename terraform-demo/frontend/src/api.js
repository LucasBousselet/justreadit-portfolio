const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '';

const fallbackBook = {
  id: 'demo-book-001',
  title: 'The Terraform Reader',
  author: {
    id: 1,
    name: 'JustReadIt Demo Library',
  },
  description:
    'A small demo book record. In the real app this would come from your ECS API backed by RDS/Postgres.',
  coverUrl: '/demo-cover.svg',
  publishedYear: 2026,
  pages: 128,
};

export async function fetchFeaturedBook() {
  if (!API_BASE_URL) {
    await delay(350);
    return fallbackBook;
  }

  const response = await fetch(`${API_BASE_URL}/demo/book`);
  if (!response.ok) {
    throw new Error(`Failed to fetch demo book: ${response.status}`);
  }

  return response.json();
}

export async function getDummyEbookDownloadUrl(bookId) {
  if (!API_BASE_URL) {
    await delay(250);
    return '/dummy-ebook.txt';
  }

  const response = await fetch(`${API_BASE_URL}/demo/books/${bookId}/download-url`);
  if (!response.ok) {
    throw new Error(`Failed to get download URL: ${response.status}`);
  }

  const payload = await response.json();
  return payload.downloadUrl;
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
