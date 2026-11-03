using IAL_QC_API.Model;
using Microsoft.Data.SqlClient;

namespace IAL_QC_API.DAL
{
    public class DALAuth
    {
        /// <summary>Returns null for an unknown or inactive user.</summary>
        public LoginUser UserGetByUserName(string userName, SqlConnection conn)
        {
            using SqlCommand cmd = DBHelper.StoredProcedure("[UserGetByUserName]", conn);
            cmd.Add("@UserName", userName);
            conn.Open();
            using SqlDataReader r = cmd.ExecuteReader();
            if (!r.Read()) return null;
            var user = new LoginUser
            {
                UserID = r.Int("UserID"),
                Name = r.Str("Name"),
                UserName = r.Str("UserName"),
                PasswordHash = r.Str("PasswordHash"),
                MustChangePassword = Convert.ToBoolean(r["MustChangePassword"]),
                IsLocked = Convert.ToBoolean(r["IsLocked"]),
                LockedUntil = r.NDate("LockedUntil")
            };
            r.NextResult();
            while (r.Read()) user.Roles.Add(r.Str("RoleName"));
            return user;
        }

        public void UserLoginSuccess(int userID, string tokenHash, string ipAddress, string userAgent, SqlConnection conn)
        {
            using SqlCommand cmd = DBHelper.StoredProcedure("[UserLoginSuccess]", conn);
            cmd.Add("@UserID", userID);
            cmd.Add("@TokenHash", tokenHash);
            cmd.Add("@IPAddress", ipAddress);
            cmd.Add("@UserAgent", userAgent);
            conn.Open();
            cmd.ExecuteNonQuery();
        }

        /// <summary>Records a wrong password. Returns the lock end time if the account is now locked.</summary>
        public DateTime? UserLoginFailed(string userName, SqlConnection conn)
        {
            using SqlCommand cmd = DBHelper.StoredProcedure("[UserLoginFailed]", conn);
            cmd.Add("@UserName", userName);
            conn.Open();
            object v = cmd.ExecuteScalar();
            return v == null || v == DBNull.Value ? null : Convert.ToDateTime(v);
        }

        /// <summary>Returns null when the session has ended or the user is inactive.</summary>
        public SessionUser UserSessionValidate(string tokenHash, SqlConnection conn)
        {
            using SqlCommand cmd = DBHelper.StoredProcedure("[UserSessionValidate]", conn);
            cmd.Add("@TokenHash", tokenHash);
            conn.Open();
            using SqlDataReader r = cmd.ExecuteReader();
            if (!r.Read()) return null;
            return new SessionUser
            {
                UserID = r.Int("UserID"),
                Name = r.Str("Name"),
                UserName = r.Str("UserName"),
                MustChangePassword = Convert.ToBoolean(r["MustChangePassword"]),
                Roles = r.Str("Roles").Split('|', StringSplitOptions.RemoveEmptyEntries).ToList()
            };
        }

        public void UserLogout(string tokenHash, SqlConnection conn)
        {
            using SqlCommand cmd = DBHelper.StoredProcedure("[UserLogout]", conn);
            cmd.Add("@TokenHash", tokenHash);
            conn.Open();
            cmd.ExecuteNonQuery();
        }

        public APIResponse UserPasswordUpdate(int userID, string passwordHash, bool mustChange, int modifiedBy, string keepTokenHash, SqlConnection conn)
        {
            var response = new APIResponse { ID = userID };
            try
            {
                using SqlCommand cmd = DBHelper.StoredProcedure("[UserPasswordUpdate]", conn);
                cmd.Add("@UserID", userID);
                cmd.Add("@PasswordHash", passwordHash);
                cmd.Add("@MustChangePassword", mustChange);
                cmd.Add("@ModifiedBy", modifiedBy);
                cmd.Add("@KeepTokenHash", keepTokenHash);
                conn.Open();
                cmd.ExecuteNonQuery();
                response.Response = "Password Updated";
            }
            catch (Exception ex)
            {
                response.ErrorMessage = ex.Message;
            }
            return response;
        }
    }
}
