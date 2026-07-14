# JustReadIt Frontend Demo

A very small Preact + Vite single-page app for the JustReadIt AWS demo project.

It demonstrates three frontend flows:

- fetching a demo book record
- showing a demo book cover
- downloading a dummy e-book

By default, it runs without a backend and uses mocked/demo data. When your ECS API is ready, set `VITE_API_BASE_URL` and the app will call your backend instead.

## Run locally

```bash
npm install
npm run dev
```

Open the local Vite URL in your browser.

## Build for S3/CloudFront

```bash
npm run build
```

The static files will be generated in:

```text
dist/
```

You can upload that folder to your website assets bucket, for example:

```bash
aws s3 sync ./dist s3://YOUR_WEBSITE_ASSETS_BUCKET --delete
```

Then invalidate CloudFront if needed:

```bash
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

## Optional backend wiring

Set this environment variable before building or running:

```bash
VITE_API_BASE_URL=https://your-api.example.com npm run dev
```

Expected backend endpoints:

```http
GET /demo/book
```

Example response:

```json
{
  "id": "demo-book-001",
  "title": "The Terraform Reader",
  "author": "JustReadIt Demo Library",
  "description": "A small demo book record from the API.",
  "coverUrl": "https://your-content-cloudfront-domain/covers/demo-cover.svg",
  "publishedYear": 2026,
  "pages": 128
}
```

```http
GET /demo/books/{bookId}/download-url
```

Example response:

```json
{
  "downloadUrl": "https://your-private-s3-presigned-url"
}
```

For the real version, the download endpoint would authenticate the user and return a short-lived S3 pre-signed URL.

## Notes

- This app uses relative paths for bundled/static assets, so it works well behind CloudFront.
- No S3 CORS is required for the bundled demo assets.
- If the real app later fetches cross-origin images/files through JavaScript, then CORS may need to be revisited.
