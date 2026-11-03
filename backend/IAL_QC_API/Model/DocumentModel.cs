namespace IAL_QC_API.Model
{
    //=========================== Inputs ===========================

    /// <summary>New document + first revision. Sent as multipart/form-data with the file.</summary>
    public class DocumentCreateModel
    {
        public string DocumentNumber { get; set; }
        public string Title { get; set; }
        public int CategoryID { get; set; }
        /// <summary>Starting revision. 1 for a new document; the current revision for an existing ISO document.</summary>
        public int RevisionNo { get; set; } = 1;
        public string ChangeSummary { get; set; }
        public int UserID { get; set; }
        public IFormFile File { get; set; }
    }

    /// <summary>New revision of an existing document. multipart/form-data with the file.</summary>
    public class DocumentVersionCreateModel
    {
        public int DocumentID { get; set; }
        /// <summary>Optional new title for the document; empty = keep the current title.</summary>
        public string Title { get; set; }
        public string ChangeSummary { get; set; }
        public int UserID { get; set; }
        public IFormFile File { get; set; }
    }

    /// <summary>Change a Draft / Rejected revision. File and Title are optional.</summary>
    public class DocumentVersionUpdateModel
    {
        public int VersionID { get; set; }
        public string Title { get; set; }
        public string ChangeSummary { get; set; }
        public int UserID { get; set; }
        public IFormFile File { get; set; }
    }

    public class DocumentSubmitModel
    {
        public int VersionID { get; set; }
        public string Comments { get; set; }
        public int UserID { get; set; }
    }

    /// <summary>Action = "Approved" or "Rejected". Comments are required when rejecting.</summary>
    public class DocumentApproveModel
    {
        public int VersionID { get; set; }
        public string Action { get; set; }
        public string Comments { get; set; }
        public int UserID { get; set; }
    }

    public class DocumentStatusModel
    {
        public int DocumentID { get; set; }
        public string IsActive { get; set; }
        public int UserID { get; set; }
    }

    //=========================== Outputs ===========================

    public class DocumentListModel
    {
        public int DocumentID { get; set; }
        public string DocumentNumber { get; set; }
        public string Title { get; set; }
        public int CategoryID { get; set; }
        public string CategoryCode { get; set; }
        public string CategoryName { get; set; }
        public string IsActive { get; set; }
        public int? VersionID { get; set; }
        public int? RevisionNo { get; set; }
        public string VersionStatus { get; set; }
        public string OriginalFileName { get; set; }
        public string FileType { get; set; }
        public int? FileSizeKB { get; set; }
        public string EditedBy { get; set; }
        public string ReviewedBy { get; set; }
        public string ApprovedBy { get; set; }
        public DateTime? IssuedDate { get; set; }
        public int? PendingVersionID { get; set; }
        public int? PendingRevisionNo { get; set; }
        public string PendingStatus { get; set; }
    }

    /// <summary>A revision of a document (current, pending, or in history).</summary>
    public class DocumentVersionModel
    {
        public int VersionID { get; set; }
        public int RevisionNo { get; set; }
        public int? StatusID { get; set; }
        public string StatusName { get; set; }
        public string OriginalFileName { get; set; }
        public string FileType { get; set; }
        public int? FileSizeKB { get; set; }
        public string ChangeSummary { get; set; }
        public string EditedBy { get; set; }
        public int? EditedByUserID { get; set; }
        public DateTime? CreatedOn { get; set; }
        public DateTime? SubmittedOn { get; set; }
        public string ReviewedBy { get; set; }
        public DateTime? ReviewedOn { get; set; }
        public string ApprovedBy { get; set; }
        public DateTime? ApprovedOn { get; set; }
        public DateTime? IssuedDate { get; set; }
    }

    public class DocumentDetailModel
    {
        public int DocumentID { get; set; }
        public string DocumentNumber { get; set; }
        public string Title { get; set; }
        public int CategoryID { get; set; }
        public string CategoryCode { get; set; }
        public string CategoryName { get; set; }
        public string IsActive { get; set; }
        public DateTime? CreatedOn { get; set; }
        public string CreatedBy { get; set; }
        /// <summary>Current approved revision (null if none approved yet).</summary>
        public DocumentVersionModel CurrentVersion { get; set; }
        /// <summary>Revision in progress or rejected (null if none).</summary>
        public DocumentVersionModel PendingVersion { get; set; }
        public string ErrorMessage { get; set; } = string.Empty;
    }

    public class DocumentLogModel
    {
        public long LogID { get; set; }
        public int RevisionNo { get; set; }
        public string ActionType { get; set; }
        public int? ApprovalLevel { get; set; }
        public string FromStatus { get; set; }
        public string ToStatus { get; set; }
        public string Comments { get; set; }
        public string ActionBy { get; set; }
        public DateTime? ActionOn { get; set; }
    }

    public class DocumentHistoryModel
    {
        public List<DocumentVersionModel> Versions { get; set; } = new List<DocumentVersionModel>();
        public List<DocumentLogModel> Log { get; set; } = new List<DocumentLogModel>();
    }

    public class PendingApprovalModel
    {
        public int VersionID { get; set; }
        public int DocumentID { get; set; }
        public string DocumentNumber { get; set; }
        public string Title { get; set; }
        public string CategoryName { get; set; }
        public int RevisionNo { get; set; }
        public string StatusName { get; set; }
        public int? ApprovalLevel { get; set; }
        public string OriginalFileName { get; set; }
        public string FileType { get; set; }
        public string ChangeSummary { get; set; }
        public string EditedBy { get; set; }
        public DateTime? SubmittedOn { get; set; }
        public string ReviewedBy { get; set; }
        public DateTime? ReviewedOn { get; set; }
    }

    /// <summary>File details of a revision (internal: used to serve downloads).</summary>
    public class DocumentFileModel
    {
        public int VersionID { get; set; }
        public string DocumentNumber { get; set; }
        public int RevisionNo { get; set; }
        public int StatusID { get; set; }
        public string OriginalFileName { get; set; }
        public string StoredFileName { get; set; }
        public string FilePath { get; set; }
        public string FileType { get; set; }
    }
}
