using IAL_QC_API.DAL;
using IAL_QC_API.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace IAL_QC_API.Controllers
{
    /// <summary>Master data: roles and document categories.</summary>
    [Route("api/[controller]")]
    [ApiController]
    public class MasterController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly DALMaster dalMaster = new DALMaster();

        public MasterController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        private SqlConnection GetConnection()
        {
            return new SqlConnection(_configuration.GetConnectionString("Conn"));
        }

        //=========================== Roles ===========================

        [HttpGet]
        [Route("RoleMasterGet")]
        public List<RoleModel> RoleMasterGet(string isActive = "Y")
        {
            using SqlConnection conn = GetConnection();
            return dalMaster.RoleMasterGet(isActive, conn);
        }

        [HttpPost]
        [Route("RoleMasterInsertUpdate")]
        [Authorize(Roles = AppRoles.Admin)]
        public APIResponse RoleMasterInsertUpdate(RoleModel model)
        {
            model.CreatedBy = User.UserId();
            using SqlConnection conn = GetConnection();
            return dalMaster.RoleMasterInsertUpdate(model, conn);
        }

        //=========================== Document categories ===========================

        [HttpGet]
        [Route("DocumentCategoryGet")]
        public List<DocumentCategoryModel> DocumentCategoryGet(string isActive = "Y")
        {
            using SqlConnection conn = GetConnection();
            return dalMaster.DocumentCategoryGet(isActive, conn);
        }

        [HttpPost]
        [Route("DocumentCategoryInsertUpdate")]
        [Authorize(Roles = AppRoles.Admin)]
        public APIResponse DocumentCategoryInsertUpdate(DocumentCategoryModel model)
        {
            model.CreatedBy = User.UserId();
            using SqlConnection conn = GetConnection();
            return dalMaster.DocumentCategoryInsertUpdate(model, conn);
        }
    }
}
