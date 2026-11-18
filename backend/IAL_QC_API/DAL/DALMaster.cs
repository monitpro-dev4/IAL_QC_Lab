using IAL_QC_API.Model;
using Microsoft.Data.SqlClient;

namespace IAL_QC_API.DAL
{
    /// <summary>Roles and document categories.</summary>
    public class DALMaster
    {
        //=========================== Roles ===========================

        public List<RoleModel> RoleMasterGet(string isActive, SqlConnection conn)
        {
            var list = new List<RoleModel>();
            using SqlCommand cmd = DBHelper.StoredProcedure("[RoleMasterGet]", conn);
            cmd.Add("@IsActive", string.IsNullOrWhiteSpace(isActive) ? null : isActive);
            conn.Open();
            using SqlDataReader r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new RoleModel
                {
                    RoleID = r.Int("RoleID"),
                    RoleName = r.Str("RoleName"),
                    RoleDesc = r.Str("RoleDesc"),
                    IsActive = r.Str("IsActive"),
                    CreatedOn = r.NDate("CreatedOn"),
                    ModifiedOn = r.NDate("ModifiedOn")
                });
            }
            return list;
        }

        public APIResponse RoleMasterInsertUpdate(RoleModel model, SqlConnection conn)
        {
            var response = new APIResponse();
            try
            {
                using SqlCommand cmd = DBHelper.StoredProcedure("[RoleMasterInsertUpdate]", conn);
                cmd.Add("@RoleID", model.RoleID);
                cmd.Add("@RoleName", model.RoleName);
                cmd.Add("@RoleDesc", model.RoleDesc);
                cmd.Add("@IsActive", model.IsActive ?? "Y");
                cmd.Add("@CreatedBy", model.CreatedBy);
                SqlParameter newId = cmd.AddOutputInt("@NewRoleID");
                conn.Open();
                cmd.ExecuteNonQuery();
                response.ID = newId.Value == DBNull.Value ? 0 : Convert.ToInt64(newId.Value);
                response.Response = model.RoleID > 0 ? "Updated Successfully" : "Inserted Successfully";
            }
            catch (Exception ex)
            {
                response.ErrorMessage = ex.Message;
            }
            return response;
        }

        //=========================== Document categories ===========================

        public List<DepartmentModel> DepartmentGet(string isActive, SqlConnection conn)
        {
            var list = new List<DepartmentModel>();
            using SqlCommand cmd = DBHelper.StoredProcedure("[DepartmentGet]", conn);
            cmd.Add("@IsActive", string.IsNullOrWhiteSpace(isActive) ? null : isActive);
            conn.Open();
            using SqlDataReader r = cmd.ExecuteReader();
            while (r.Read())
                list.Add(new DepartmentModel { DepartmentID = r.Int("DepartmentID"), DepartmentName = r.Str("DepartmentName"), IsActive = r.Str("IsActive") });
            return list;
        }

        public List<PlantAreaModel> PlantAreaGet(string isActive, SqlConnection conn)
        {
            var list = new List<PlantAreaModel>();
            using SqlCommand cmd = DBHelper.StoredProcedure("[PlantAreaGet]", conn);
            cmd.Add("@IsActive", string.IsNullOrWhiteSpace(isActive) ? null : isActive);
            conn.Open();
            using SqlDataReader r = cmd.ExecuteReader();
            while (r.Read())
                list.Add(new PlantAreaModel { PlantAreaID = r.Int("PlantAreaID"), PlantAreaName = r.Str("PlantAreaName"), IsActive = r.Str("IsActive") });
            return list;
        }

        public List<DocumentCategoryModel> DocumentCategoryGet(string isActive, SqlConnection conn)
        {
            var list = new List<DocumentCategoryModel>();
            using SqlCommand cmd = DBHelper.StoredProcedure("[DocumentCategoryGet]", conn);
            cmd.Add("@IsActive", string.IsNullOrWhiteSpace(isActive) ? null : isActive);
            conn.Open();
            using SqlDataReader r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new DocumentCategoryModel
                {
                    CategoryID = r.Int("CategoryID"),
                    CategoryCode = r.Str("CategoryCode"),
                    CategoryName = r.Str("CategoryName"),
                    CategoryDesc = r.Str("CategoryDesc"),
                    IsActive = r.Str("IsActive"),
                    CreatedOn = r.NDate("CreatedOn"),
                    ModifiedOn = r.NDate("ModifiedOn")
                });
            }
            return list;
        }

        public APIResponse DocumentCategoryInsertUpdate(DocumentCategoryModel model, SqlConnection conn)
        {
            var response = new APIResponse();
            try
            {
                using SqlCommand cmd = DBHelper.StoredProcedure("[DocumentCategoryInsertUpdate]", conn);
                cmd.Add("@CategoryID", model.CategoryID);
                cmd.Add("@CategoryCode", model.CategoryCode);
                cmd.Add("@CategoryName", model.CategoryName);
                cmd.Add("@CategoryDesc", model.CategoryDesc);
                cmd.Add("@IsActive", model.IsActive ?? "Y");
                cmd.Add("@CreatedBy", model.CreatedBy);
                SqlParameter newId = cmd.AddOutputInt("@NewCategoryID");
                conn.Open();
                cmd.ExecuteNonQuery();
                response.ID = newId.Value == DBNull.Value ? 0 : Convert.ToInt64(newId.Value);
                response.Response = model.CategoryID > 0 ? "Updated Successfully" : "Inserted Successfully";
            }
            catch (Exception ex)
            {
                response.ErrorMessage = ex.Message;
            }
            return response;
        }
    }
}
