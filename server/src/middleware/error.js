// Centralized error handler. Mount as the LAST app.use(...)
function errorHandler(err, req, res, _next) {
  // Multer errors
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ error: 'file_too_large' });
  }
  if (err.message === 'only_image_allowed') {
    return res.status(415).json({ error: 'only_image_allowed' });
  }

  // JSON parse errors
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'invalid_json' });
  }
  if (err.type === 'entity.too.large') {
    return res.status(413).json({ error: 'payload_too_large' });
  }

  // Rate limit errors
  if (err.status === 429) {
    return res.status(429).json({ error: 'rate_limited' });
  }

  console.error('[server] unhandled error:', err);
  return res.status(500).json({
    error: 'server_error',
    detail: process.env.NODE_ENV === 'production' ? undefined : err.message,
  });
}

// 404 handler
function notFound(req, res) {
  res.status(404).json({ error: 'not_found', path: req.path });
}

module.exports = { errorHandler, notFound };
