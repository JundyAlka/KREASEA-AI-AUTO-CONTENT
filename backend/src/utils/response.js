/**
 * STANDARD RESPONSE HELPERS
 * ─────────────────────────────────────────────────────────
 * Semua endpoint menggunakan wrapper yang konsisten.
 */

function successResponse(data, meta = {}) {
  return {
    success: true,
    data,
    error: null,
    meta: {
      timestamp: new Date().toISOString(),
      ...meta,
    },
  };
}

function errorResponse(code, message, statusCode = 400) {
  return {
    success: false,
    data: null,
    error: { code, message },
    meta: { timestamp: new Date().toISOString() },
    _statusCode: statusCode, // dipakai oleh reply.code()
  };
}

module.exports = { successResponse, errorResponse };
