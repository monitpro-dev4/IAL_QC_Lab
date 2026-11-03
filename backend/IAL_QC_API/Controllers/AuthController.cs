using IAL_QC_API.DAL;
using IAL_QC_API.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System.Security.Claims;

namespace IAL_QC_API.Controllers
{
    /// <summary>Sign in, sign out, change password, and first-time setup.</summary>
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private const string WrongLogin = "Invalid Username Or Password";
        // Checked against when the username is unknown, so a wrong username and a
        // wrong password take the same time (no clue which usernames exist).
        private static readonly string DummyHash = PasswordRules.Hash("not-a-real-password-1");

        private readonly IConfiguration _configuration;
        private readonly DALAuth dalAuth = new DALAuth();
        private readonly DALUser dalUser = new DALUser();

        public AuthController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        private SqlConnection GetConnection() => new SqlConnection(_configuration.GetConnectionString("Conn"));

        [AllowAnonymous]
        [HttpPost]
        [Route("Login")]
        public LoginResponse Login(LoginRequest request)
        {
            string userName = request?.UserName?.Trim();
            if (string.IsNullOrEmpty(userName) || string.IsNullOrEmpty(request.Password))
                return new LoginResponse { ErrorMessage = "Enter Your Username And Password" };

            LoginUser user;
            using (SqlConnection c = GetConnection()) user = dalAuth.UserGetByUserName(userName, c);

            if (user == null)
            {
                PasswordRules.Verify(request.Password, DummyHash);
                return new LoginResponse { ErrorMessage = WrongLogin };
            }

            if (user.IsLocked)
                return new LoginResponse { ErrorMessage = LockedMessage(user.LockedUntil) };

            if (!PasswordRules.Verify(request.Password, user.PasswordHash))
            {
                DateTime? lockedUntil;
                using (SqlConnection c = GetConnection()) lockedUntil = dalAuth.UserLoginFailed(userName, c);
                return new LoginResponse { ErrorMessage = lockedUntil != null ? LockedMessage(lockedUntil) : WrongLogin };
            }

            string token = LoginToken.NewToken();
            using (SqlConnection c = GetConnection())
                dalAuth.UserLoginSuccess(user.UserID, LoginToken.Hash(token),
                    HttpContext.Connection.RemoteIpAddress?.ToString(), Request.Headers.UserAgent.ToString(), c);

            return new LoginResponse
            {
                Token = token,
                UserID = user.UserID,
                Name = user.Name,
                UserName = user.UserName,
                Roles = user.Roles,
                MustChangePassword = user.MustChangePassword
            };
        }

        [HttpPost]
        [Route("Logout")]
        public APIResponse Logout()
        {
            using SqlConnection conn = GetConnection();
            dalAuth.UserLogout(User.FindFirstValue(LoginToken.TokenHashClaim), conn);
            return new APIResponse { Response = "Signed Out" };
        }

        /// <summary>The signed-in user. The frontend calls this on start-up to check the saved token is still valid.</summary>
        [HttpGet]
        [Route("Me")]
        public LoginResponse Me()
        {
            return new LoginResponse
            {
                UserID = User.UserId(),
                Name = User.FindFirstValue("full_name"),
                UserName = User.Identity?.Name,
                Roles = User.FindAll(ClaimTypes.Role).Select(c => c.Value).ToList(),
                MustChangePassword = User.FindFirstValue(LoginToken.MustChangePasswordClaim) == "1"
            };
        }

        /// <summary>Change your own password. Your other sessions are signed out; this one stays.</summary>
        [HttpPost]
        [Route("ChangePassword")]
        public APIResponse ChangePassword(ChangePasswordRequest request)
        {
            LoginUser user;
            using (SqlConnection c = GetConnection()) user = dalAuth.UserGetByUserName(User.Identity?.Name, c);
            if (user == null) return new APIResponse { ErrorMessage = "User Not Found" };

            if (!PasswordRules.Verify(request.CurrentPassword, user.PasswordHash))
                return new APIResponse { ErrorMessage = "Current Password Is Wrong" };

            string error = PasswordRules.Validate(request.NewPassword, user.UserName);
            if (error != string.Empty) return new APIResponse { ErrorMessage = error };
            if (request.NewPassword == request.CurrentPassword)
                return new APIResponse { ErrorMessage = "Choose A Password Different From The Current One" };

            using SqlConnection conn = GetConnection();
            return dalAuth.UserPasswordUpdate(user.UserID, PasswordRules.Hash(request.NewPassword), false,
                user.UserID, User.FindFirstValue(LoginToken.TokenHashClaim), conn);
        }

        //=========================== First-time setup ===========================

        [AllowAnonymous]
        [HttpGet]
        [Route("SetupStatus")]
        public SetupStatus GetSetupStatus()
        {
            using SqlConnection conn = GetConnection();
            return new SetupStatus { NeedsSetup = dalUser.UsersGet(null, 0, null, conn).Count == 0 };
        }

        /// <summary>Creates the first Administrator and signs them in. Refused once any user exists.</summary>
        [AllowAnonymous]
        [HttpPost]
        [Route("Setup")]
        public LoginResponse Setup(SetupRequest request)
        {
            using (SqlConnection c = GetConnection())
                if (dalUser.UsersGet(null, 0, null, c).Count > 0)
                    return new LoginResponse { ErrorMessage = "Setup Is Already Done. Please Sign In." };

            string error = PasswordRules.Validate(request.Password, request.UserName);
            if (error != string.Empty) return new LoginResponse { ErrorMessage = error };

            int adminRoleId;
            using (SqlConnection c = GetConnection())
                adminRoleId = new DALMaster().RoleMasterGet("Y", c).FirstOrDefault(r => r.RoleName == AppRoles.Admin)?.RoleID ?? 0;
            if (adminRoleId == 0) return new LoginResponse { ErrorMessage = "Administrator Role Not Found. Run The Seed Scripts." };

            string hash = PasswordRules.Hash(request.Password);
            var model = new UserModel
            {
                UserID = 0, Name = request.Name, EmployeeID = request.EmployeeID, UserName = request.UserName?.Trim(),
                IsActive = "Y", RoleIDs = adminRoleId.ToString(), CreatedBy = 0
            };
            APIResponse created;
            using (SqlConnection c = GetConnection()) created = dalUser.UserInsertUpdate(model, hash, c);
            if (created.ErrorMessage != string.Empty) return new LoginResponse { ErrorMessage = created.ErrorMessage };

            // They chose this password themselves, so no forced change
            using (SqlConnection c = GetConnection())
                dalAuth.UserPasswordUpdate((int)created.ID, hash, false, (int)created.ID, null, c);

            return Login(new LoginRequest { UserName = model.UserName, Password = request.Password });
        }

        private static string LockedMessage(DateTime? until) =>
            $"Too Many Wrong Passwords. Try Again After {until:HH:mm}";
    }
}
