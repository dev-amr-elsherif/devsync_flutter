/**
 * DevSync — Firebase Cloud Functions
 *
 * Function: exchangeGitHubToken
 * ─────────────────────────────────────────────────────────────────────────────
 * GitHub's OAuth flow requires a Client Secret to exchange an authorization
 * code for an access token. The secret MUST live server-side — this function
 * acts as the secure broker between the mobile app and GitHub.
 *
 * Deploy steps:
 *   1. firebase functions:secrets:set GITHUB_CLIENT_SECRET
 *      (paste: 67755c7f48735a963722bd7734c338dac2476627)
 *   2. npm install    (inside the functions/ directory)
 *   3. firebase deploy --only functions
 *
 * The mobile app calls this via:
 *   FirebaseFunctions.instance
 *     .httpsCallable('exchangeGitHubToken')
 *     .call({'code': oauthCode});
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const axios = require('axios');

// ── Secret definition ──────────────────────────────────────────────────────
// Value is stored in Google Secret Manager, injected at runtime.
// Set it once with: firebase functions:secrets:set GITHUB_CLIENT_SECRET
const githubClientSecret = defineSecret('GITHUB_CLIENT_SECRET');

// ── GitHub OAuth Config (public values — safe here) ───────────────────────
const GITHUB_CLIENT_ID    = 'Ov23liGJL09c0Oqc2Tbk';
const GITHUB_TOKEN_URL    = 'https://github.com/login/oauth/access_token';

// ── Cloud Function ─────────────────────────────────────────────────────────
exports.exchangeGitHubToken = onCall(
  { secrets: [githubClientSecret] },
  async (request) => {
    // ── Auth guard: caller must be an anonymous/unauthed Firebase session ──
    // (We allow unauthenticated calls because this IS the auth step)
    const code = request.data?.code;

    if (!code || typeof code !== 'string' || code.trim() === '') {
      throw new HttpsError(
        'invalid-argument',
        'Missing or invalid "code" parameter.',
      );
    }

    try {
      const response = await axios.post(
        GITHUB_TOKEN_URL,
        {
          client_id:     GITHUB_CLIENT_ID,
          client_secret: githubClientSecret.value(), // injected from Secret Manager
          code:          code,
        },
        { headers: { Accept: 'application/json' } },
      );

      // GitHub returns { access_token, token_type, scope } on success
      // or { error, error_description } on failure
      if (response.data.error) {
        throw new HttpsError(
          'unauthenticated',
          response.data.error_description || 'GitHub OAuth failed',
        );
      }

      return {
        access_token: response.data.access_token,
        token_type:   response.data.token_type,
        scope:        response.data.scope,
      };

    } catch (err) {
      // Re-throw HttpsErrors as-is
      if (err instanceof HttpsError) throw err;

      console.error('[exchangeGitHubToken] Unexpected error:', err.message);
      throw new HttpsError('internal', 'GitHub token exchange failed.');
    }
  },
);
