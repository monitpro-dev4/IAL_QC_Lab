using IAL_QC_API.Model;
using Microsoft.Data.SqlClient;

namespace IAL_QC_API.DAL
{
    public class DALUser
    {
        /// <param name="passwordHash">BCrypt hash for a new user; null on update keeps the current password.</param>
        public APIResponse UserInsertUpdate(UserModel model, string passwordHash, SqlConnection conn)
        {
            var response = new APIResponse();
            try
            {
                using SqlCommand cmd = DBHelper.StoredProcedure("[UserInsertUpdate]", conn);
                cmd.Add("@UserID", model.UserID);
                cmd.Add("@Name", model.Name);
                cmd.Add("@EmployeeID", model.EmployeeID);
                cmd.Add("@UserName", model.UserName);
                cmd.Add("@PasswordHash", passwordHash);
                cmd.Add("@EmailAddress", model.EmailAddress);
                cmd.Add("@MobileNo", model.MobileNo);
                cmd.Add("@Designation", model.Designation);
                cmd.Add("@UserImage", model.UserImage);
                cmd.Add("@IsActive", model.IsActive ?? "Y");
                cmd.Add("@RoleIDs", model.RoleIDs);
                cmd.Add("@CreatedBy", model.CreatedBy);
                SqlParameter newId = cmd.AddOutputInt("@NewUserID");
                conn.Open();
                cmd.ExecuteNonQuery();
                response.ID = newId.Value == DBNull.Value ? 0 : Convert.ToInt64(newId.Value);
                response.Response = model.UserID > 0 ? "Updated Successfully" : "Inserted Successfully";
            }
            catch (Exception ex)
            {
                response.ErrorMessage = ex.Message;
            }
            return response;
        }

        public List<UserListModel> UsersGet(string search, int roleID, string isActive, SqlConnection conn)
        {
            var list = new List<UserListModel>();
            using SqlCommand cmd = DBHelper.StoredProcedure("[UsersGet]", conn);
            cmd.Add("@Search", string.IsNullOrWhiteSpace(search) ? null : search);
            cmd.Add("@RoleID", roleID);
            cmd.Add("@IsActive", string.IsNullOrWhiteSpace(isActive) ? null : isActive);
            conn.Open();
            using SqlDataReader r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new UserListModel
                {
                    UserID = r.Int("UserID"),
                    Name = r.Str("Name"),
                    EmployeeID = r.Str("EmployeeID"),
                    UserName = r.Str("UserName"),
                    EmailAddress = r.Str("EmailAddress"),
                    MobileNo = r.Str("MobileNo"),
                    Designation = r.Str("Designation"),
                    UserImage = r.Str("UserImage"),
                    IsActive = r.Str("IsActive"),
                    CreatedOn = r.NDate("CreatedOn"),
                    ModifiedOn = r.NDate("ModifiedOn"),
                    RoleIDs = r.Str("RoleIDs"),
                    RoleNames = r.Str("RoleNames")
                });
            }
            return list;
        }

        public UserDetailModel UserGet(int userID, SqlConnection conn)
        {
            var model = new UserDetailModel();
            try
            {
                using SqlCommand cmd = DBHelper.StoredProcedure("[UserGet]", conn);
                cmd.Add("@UserID", userID);
                conn.Open();
                using SqlDataReader r = cmd.ExecuteReader();
                if (!r.Read())
                {
                    model.ErrorMessage = "User Not Found";
                    return model;
                }
                model.UserID = r.Int("UserID");
                model.Name = r.Str("Name");
                model.EmployeeID = r.Str("EmployeeID");
                model.UserName = r.Str("UserName");
                model.EmailAddress = r.Str("EmailAddress");
                model.MobileNo = r.Str("MobileNo");
                model.Designation = r.Str("Designation");
                model.UserImage = r.Str("UserImage");
                model.IsActive = r.Str("IsActive");
                model.CreatedBy = r.NInt("CreatedBy");
                model.CreatedOn = r.NDate("CreatedOn");
                model.ModifiedBy = r.NInt("ModifiedBy");
                model.ModifiedOn = r.NDate("ModifiedOn");

                r.NextResult();
                while (r.Read())
                {
                    model.Roles.Add(new RoleModel { RoleID = r.Int("RoleID"), RoleName = r.Str("RoleName") });
                }
            }
            catch (Exception ex)
            {
                model.ErrorMessage = ex.Message;
            }
            return model;
        }

        public APIResponse UserActiveStatusUpdate(UserStatusModel model, SqlConnection conn)
        {
            var response = new APIResponse { ID = model.UserID };
            try
            {
                using SqlCommand cmd = DBHelper.StoredProcedure("[UserActiveStatusUpdate]", conn);
                cmd.Add("@UserID", model.UserID);
                cmd.Add("@IsActive", model.IsActive);
                cmd.Add("@ModifiedBy", model.ModifiedBy);
                conn.Open();
                cmd.ExecuteNonQuery();
                response.Response = model.IsActive == "Y" ? "User Activated" : "User Deactivated";
            }
            catch (Exception ex)
            {
                response.ErrorMessage = ex.Message;
            }
            return response;
        }
    }
}
