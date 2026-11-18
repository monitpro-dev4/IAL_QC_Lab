using IAL_QC_API.Model;
using Microsoft.Data.SqlClient;

namespace IAL_QC_API.DAL
{
    public class DALDashboard
    {
        public DashboardModel DashboardSummary(int userID, bool canViewDrafts, SqlConnection conn)
        {
            var model = new DashboardModel();
            using SqlCommand cmd = DBHelper.StoredProcedure("[DashboardSummary]", conn);
            cmd.Add("@UserID", userID);
            cmd.Add("@CanViewDrafts", canViewDrafts);
            conn.Open();
            using SqlDataReader r = cmd.ExecuteReader();
            if (r.Read())
            {
                model.Counts = new DashboardCounts
                {
                    ApprovedDocuments = r.Int("ApprovedDocuments"),
                    InReview = r.Int("InReview"),
                    Drafts = r.Int("Drafts"),
                    Rejected = r.Int("Rejected"),
                    WaitingForMe = r.Int("WaitingForMe"),
                    MyOpenRevisions = r.Int("MyOpenRevisions"),
                    MyRejected = r.Int("MyRejected"),
                    ApprovedLast30Days = r.Int("ApprovedLast30Days")
                };
            }
            r.NextResult();
            while (r.Read())
            {
                model.Categories.Add(new DashboardCategory
                {
                    CategoryID = r.Int("CategoryID"),
                    CategoryCode = r.Str("CategoryCode"),
                    CategoryName = r.Str("CategoryName"),
                    Documents = r.Int("Documents")
                });
            }
            r.NextResult();
            while (r.Read())
            {
                model.Activity.Add(new DashboardActivity
                {
                    LogID = r.Long("LogID"),
                    DocumentID = r.Int("DocumentID"),
                    DocumentNumber = r.Str("DocumentNumber"),
                    Title = r.Str("Title"),
                    RevisionNo = r.Int("RevisionNo"),
                    ActionType = r.Str("ActionType"),
                    ApprovalLevel = r.NInt("ApprovalLevel"),
                    ActionBy = r.Str("ActionBy"),
                    ActionOn = r.NDate("ActionOn")
                });
            }
            r.NextResult();
            while (r.Read())
            {
                model.Months.Add(new DashboardMonth
                {
                    MonthStart = r.NDate("MonthStart") ?? DateTime.MinValue,
                    Uploaded = r.Int("Uploaded"),
                    Approved = r.Int("Approved"),
                    Rejected = r.Int("Rejected")
                });
            }
            r.NextResult();
            if (r.Read())
            {
                model.ApprovalTime = new DashboardApprovalTime
                {
                    ApprovedRevisions = r.Int("ApprovedRevisions"),
                    AvgTotalHours = r.NDec("AvgTotalHours"),
                    AvgReviewHours = r.NDec("AvgReviewHours"),
                    AvgManagerHours = r.NDec("AvgManagerHours")
                };
            }
            return model;
        }
    }
}
