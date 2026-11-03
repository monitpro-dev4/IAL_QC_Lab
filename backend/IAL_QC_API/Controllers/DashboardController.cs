using IAL_QC_API.DAL;
using IAL_QC_API.Model;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace IAL_QC_API.Controllers
{
    /// <summary>Home page numbers for the signed-in user.</summary>
    [Route("api/[controller]")]
    [ApiController]
    public class DashboardController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly DALDashboard dalDashboard = new DALDashboard();

        public DashboardController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [HttpGet]
        [Route("DashboardSummary")]
        public DashboardModel DashboardSummary()
        {
            using var conn = new SqlConnection(_configuration.GetConnectionString("Conn"));
            return dalDashboard.DashboardSummary(User.UserId(), User.IsInAnyRole(AppRoles.DraftViewers), conn);
        }
    }
}
