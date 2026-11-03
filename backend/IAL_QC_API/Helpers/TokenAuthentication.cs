using IAL_QC_API.DAL;
using IAL_QC_API.Model;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Options;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;

namespace IAL_QC_API
{
    /// <summary>
    /// Login tokens: a random value given to the browser at login and sent back
    /// as "Authorization: Bearer &lt;token&gt;" on every request. Only its SHA-256
    /// hash is stored (UserLoginHistory). Every request is checked against the
    /// database, so sign out, a password reset or deactivating the user takes
    /// effect immediately.
    /// </summary>
    public static class LoginToken
    {
        public const string Scheme = "Token";
        public const string TokenHashClaim = "token_hash";
        public const string MustChangePasswordClaim = "must_change_password";

        public static string NewToken() =>
            Convert.ToBase64String(RandomNumberGenerator.GetBytes(32)).TrimEnd('=').Replace('+', '-').Replace('/', '_');

        public static string Hash(string token) =>
            Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(token)));

        /// <summary>The signed-in user's UserID (from the token, never from the request body).</summary>
        public static int UserId(this ClaimsPrincipal user) =>
            int.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out int id) ? id : 0;

        public static bool IsInAnyRole(this ClaimsPrincipal user, IEnumerable<string> roles) => roles.Any(user.IsInRole);
    }

    public class TokenAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
    {
        private readonly IConfiguration _configuration;
        private readonly DALAuth _dal = new DALAuth();

        public TokenAuthenticationHandler(IOptionsMonitor<AuthenticationSchemeOptions> options, ILoggerFactory logger,
            UrlEncoder encoder, IConfiguration configuration) : base(options, logger, encoder)
        {
            _configuration = configuration;
        }

        protected override Task<AuthenticateResult> HandleAuthenticateAsync()
        {
            string header = Request.Headers.Authorization.ToString();
            if (!header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
                return Task.FromResult(AuthenticateResult.NoResult());

            string token = header.Substring(7).Trim();
            if (token.Length == 0) return Task.FromResult(AuthenticateResult.NoResult());

            string hash = LoginToken.Hash(token);
            SessionUser session;
            using (var conn = new SqlConnection(_configuration.GetConnectionString("Conn")))
                session = _dal.UserSessionValidate(hash, conn);

            if (session == null) return Task.FromResult(AuthenticateResult.Fail("Session ended"));

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, session.UserID.ToString()),
                new Claim(ClaimTypes.Name, session.UserName),
                new Claim("full_name", session.Name),
                new Claim(LoginToken.TokenHashClaim, hash),
                new Claim(LoginToken.MustChangePasswordClaim, session.MustChangePassword ? "1" : "0"),
            };
            claims.AddRange(session.Roles.Select(r => new Claim(ClaimTypes.Role, r)));

            var principal = new ClaimsPrincipal(new ClaimsIdentity(claims, LoginToken.Scheme));
            return Task.FromResult(AuthenticateResult.Success(new AuthenticationTicket(principal, LoginToken.Scheme)));
        }

        protected override async Task HandleChallengeAsync(AuthenticationProperties properties)
        {
            Response.StatusCode = StatusCodes.Status401Unauthorized;
            await Response.WriteAsJsonAsync(new APIResponse { ErrorMessage = "Please Sign In Again" });
        }

        protected override async Task HandleForbiddenAsync(AuthenticationProperties properties)
        {
            Response.StatusCode = StatusCodes.Status403Forbidden;
            await Response.WriteAsJsonAsync(new APIResponse { ErrorMessage = "You Do Not Have Permission To Do This" });
        }
    }
}
