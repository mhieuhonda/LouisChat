const rateLimit = require('express-rate-limit');

// Strict limiter for auth endpoints (prevents brute-force)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 30,                  // 30 attempts per IP per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'too_many_auth_attempts' },
});

// Generic limiter for all other API routes
const apiLimiter = rateLimit({
  windowMs: 1 * 60 * 1000,  // 1 min
  max: 120,                 // 120 requests per IP per minute
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'rate_limited' },
});

// Upload limiter — stricter
const uploadLimiter = rateLimit({
  windowMs: 1 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'too_many_uploads' },
});

module.exports = { authLimiter, apiLimiter, uploadLimiter };
