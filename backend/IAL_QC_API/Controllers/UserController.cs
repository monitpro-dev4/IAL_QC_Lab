using IAL_QC_API.DAL;
using IAL_QC_API.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace IAL_QC_API.Controllers
{
    /// <summary>User management: Administrator only.</summary>
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = AppRoles.Admin)]
    public class UserController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly DALUser dalUser = new DALUser();

        public UserController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        private SqlConnection GetConnection()
        {
            return new SqlConnection(_configuration.GetConnectionString("Conn"));
        }

        /// <summary>Add (UserID = 0) or update a user and their roles.</summary>
        [HttpPost]
        [Route("UserInsertUpdate")]
        public APIResponse UserInsertUpdate(UserModel model)
        {
            model.CreatedBy = User.UserId();
            string hash = null;
            if (model.UserID == 0)
            {
                string error = PasswordRules.Validate(model.Password, model.UserName);
                if (error != string.Empty) return new APIResponse { ErrorMessage = error };
                hash = PasswordRules.Hash(model.Password);
            }
            if (model.UserID == User.UserId() && model.IsActive == "N")
                return new APIResponse { ErrorMessage = "You Cannot Deactivate Yourself" };

            using SqlConnection conn = GetConnection();
            return dalUser.UserInsertUpdate(model, hash, conn);
        }

        /// <summary>User list. roleId 0 = all roles; isActive empty = all.</summary>
        [HttpGet]
        [Route("UsersGet")]
        public List<UserListModel> UsersGet(string search = null, int roleId = 0, string isActive = null)
        {
            using SqlConnection conn = GetConnection();
            return dalUser.UsersGet(search, roleId, isActive, conn);
        }

        [HttpGet]
        [Route("UserGet")]
        public UserDetailModel UserGet(int userId)
        {
            using SqlConnection conn = GetConnection();
            return dalUser.UserGet(userId, conn);
        }

        [HttpPost]
        [Route("UserActiveStatusUpdate")]
        public APIResponse UserActiveStatusUpdate(UserStatusModel model)
        {
            model.ModifiedBy = User.UserId();
            if (model.UserID == model.ModifiedBy && model.IsActive == "N")
                return new APIResponse { ErrorMessage = "You Cannot Deactivate Yourself" };
            using SqlConnection conn = GetConnection();
            return dalUser.UserActiveStatusUpdate(model, conn);
        }

        /// <summary>Set a new temporary password. The user must change it at next login; all their sessions end.</summary>
        [HttpPost]
        [Route("UserPasswordReset")]
        public APIResponse UserPasswordReset(UserPasswordResetModel model)
        {
            UserDetailModel target;
            using (SqlConnection c = GetConnection()) target = dalUser.UserGet(model.UserID, c);
            if (target.ErrorMessage != string.Empty) return new APIResponse { ErrorMessage = target.ErrorMessage };

            string error = PasswordRules.Validate(model.NewPassword, target.UserName);
            if (error != string.Empty) return new APIResponse { ErrorMessage = error };

            using SqlConnection conn = GetConnection();
            APIResponse response = new DALAuth().UserPasswordUpdate(model.UserID, PasswordRules.Hash(model.NewPassword), false, User.UserId(), null, conn);   // the new password is final, no forced change
            if (response.ErrorMessage == string.Empty) response.Response = "Password Reset.";
            return response;
        }
    }
}
