namespace IAL_QC_API.Model
{
    public class DashboardCounts
    {
        public int ApprovedDocuments { get; set; }
        public int InReview { get; set; }
        public int Drafts { get; set; }
        public int Rejected { get; set; }
        public int WaitingForMe { get; set; }
        public int MyOpenRevisions { get; set; }
        public int MyRejected { get; set; }
        public int ApprovedLast30Days { get; set; }
    }

    public class DashboardCategory
    {
        public int CategoryID { get; set; }
        public string CategoryCode { get; set; }
        public string CategoryName { get; set; }
        public int Documents { get; set; }
    }

    public class DashboardActivity
    {
        public long LogID { get; set; }
        public int DocumentID { get; set; }
        public string DocumentNumber { get; set; }
        public string Title { get; set; }
        public int RevisionNo { get; set; }
        public string ActionType { get; set; }
        public int? ApprovalLevel { get; set; }
        public string ActionBy { get; set; }
        public DateTime? ActionOn { get; set; }
    }

    public class DashboardModel
    {
        public DashboardCounts Counts { get; set; } = new DashboardCounts();
        public List<DashboardCategory> Categories { get; set; } = new List<DashboardCategory>();
        public List<DashboardActivity> Activity { get; set; } = new List<DashboardActivity>();
    }
}
