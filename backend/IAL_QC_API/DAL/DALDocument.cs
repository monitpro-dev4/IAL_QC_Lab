using IAL_QC_API.Model;
using Microsoft.Data.SqlClient;

namespace IAL_QC_API.DAL
{
    /// <summary>
    /// Document Management. Every method calls one stored procedure;
    /// workflow rules (roles, statuses, approvals) are enforced in the SPs.
    /// File saving happens in the controller (see Helpers/FileStorage.cs);
    /// the DAL only stores the file details.
    /// </summary>
    public class DALDocument
    {
        //=========================== Create / update ===========================

        public APIResponse DocumentCreate(DocumentCreateModel model, StoredFile file, SqlConnection conn)
        {
            var response = new APIResponse();
            try
            {
                using SqlCommand cmd = DBHelper.StoredProcedure("[DocumentCreate]", conn);
                cmd.Add("@DocumentNumber", model.DocumentNumber);
                cmd.Add("@Title", model.Title);
                cmd.Add("@CategoryID", model.CategoryID > 0 ? model.CategoryID : null);   // category is optional
                cmd.Add("@RevisionNo", model.RevisionNo);
                cmd.Add("@OriginalFileName", file.OriginalFileName);
                cmd.Add("@StoredFileName", file.StoredFileName);
                cmd.Add("@FilePath", file.RelativeFolder);
                cmd.Add("@FileType", file.FileType);
                cmd.Add("@FileSizeKB", file.FileSizeKB);
                cmd.Add("@ChangeSummary", model.ChangeSummary);
                cmd.Add("@UserID", model.UserID);
                cmd.Add("@Department", model.Department);
                cmd.Add("@PlantArea", model.PlantArea);
                cmd.Add("@Remarks", model.Remarks);
                SqlParameter docId = cmd.AddOutputInt("@NewDocumentID");
                SqlParameter verId = cmd.AddOutputInt("@NewVersionID");
                conn.Open();
                cmd.ExecuteNonQuery();
                response.ID = docId.Value == DBNull.Value ? 0 : Convert.ToInt64(docId.Value);
                response.SecondID = verId.Value == DBNull.Value ? 0 : Convert.ToInt64(verId.Value);
                response.Response = "Document Created As Draft";
            }
            catch (Exception ex)
            {
                response.ErrorMessage = ex.Message;
            }
            return response;
        }

        public APIResponse DocumentVersionCreate(DocumentVersionCreateModel model, StoredFile file, SqlConnection conn)
        {
            var response = new APIResponse();
            try
            {
                using SqlCommand cmd = DBHelper.StoredProcedure("[DocumentVersionCreate]", conn);
                cmd.Add("@DocumentID", model.DocumentID);
                cmd.Add("@Title", model.Title);
                cmd.Add("@ReasonForChange", model.ReasonForChange);
                cmd.Add("@OriginalFileName", file.OriginalFileName);
                cmd.Add("@StoredFileName", file.StoredFileName);
                cmd.Add("@FilePath", file.RelativeFolder);
                cmd.Add("@FileType", file.FileType);
                cmd.Add("@FileSizeKB", file.FileSizeKB);
                cmd.Add("@ChangeSummary", model.ChangeSummary);
                cmd.Add("@UserID", model.UserID);
                SqlParameter verId = cmd.AddOutputInt("@NewVersionID");
                conn.Open();
                cmd.ExecuteNonQuery();
                response.ID = verId.Value == DBNull.Value ? 0 : Convert.ToInt64(verId.Value);
                response.Response = "New Revision Created As Draft";
            }
            catch (Exception ex)
            {
                response.ErrorMessage = ex.Message;
            }
            return response;
        }

        /// <summary>file is null when only the title / change summary changes.</summary>
        public APIResponse DocumentVersionUpdate(DocumentVersionUpdateModel model, StoredFile file, SqlConnection conn)
        {
            var response = new APIResponse { ID = model.VersionID };
            try
            {
                using SqlCommand cmd = DBHelper.StoredProcedure("[DocumentVersionUpdate]", conn);
                cmd.Add("@VersionID", model.VersionID);
                cmd.Add("@Title", model.Title);
                cmd.Add("@OriginalFileName", file?.OriginalFileName);
                cmd.Add("@StoredFileName", file?.StoredFileName);
                cmd.Add("@FilePath", file?.RelativeFolder);
                cmd.Add("@FileType", file?.FileType);
                cmd.Add("@FileSizeKB", file?.FileSizeKB);
                cmd.Add("@ChangeSummary", model.ChangeSummary);
                cmd.Add("@UserID", model.UserID);
                conn.Open();
                cmd.ExecuteNonQuery();
                response.Response = "Revision Updated";
            }
            catch (Exception ex)
            {
                response.ErrorMessage = ex.Message;
            }
            return response;
        }

        //=========================== Workflow ===========================

        public APIResponse DocumentVersionSubmit(DocumentSubmitModel model, SqlConnection conn)
        {
            var response = new APIResponse { ID = model.VersionID };
            try
            {
                using SqlCommand cmd = DBHelper.StoredProcedure("[DocumentVersionSubmit]", conn);
                cmd.Add("@VersionID", model.VersionID);
                cmd.Add("@Comments", model.Comments);
                cmd.Add("@UserID", model.UserID);
                conn.Open();
                cmd.ExecuteNonQuery();
                response.Response = "Submitted For Approval";
            }
            catch (Exception ex)
            {
                response.ErrorMessage = ex.Message;
            }
            return response;
        }

        public APIResponse DocumentVersionApprove(DocumentApproveModel model, SqlConnection conn)
        {
            var response = new APIResponse { ID = model.VersionID };
            try
            {
                using SqlCommand cmd = DBHelper.StoredProcedure("[DocumentVersionApprove]", conn);
                cmd.Add("@VersionID", model.VersionID);
                cmd.Add("@Action", model.Action);
                cmd.Add("@Comments", model.Comments);
                cmd.Add("@UserID", model.UserID);
                conn.Open();
                cmd.ExecuteNonQuery();
                response.Response = model.Action == "Rejected" ? "Revision Rejected" : "Revision Approved";
            }
            catch (Exception ex)
            {
                response.ErrorMessage = ex.Message;
            }
            return response;
        }

        /// <summary>Lab Manager: Action = "Cancel", "Archive" or "Restore".</summary>
        public APIResponse DocumentStatusChange(DocumentApproveModel model, SqlConnection conn)
        {
            var response = new APIResponse { ID = model.VersionID };
            try
            {
                using SqlCommand cmd = DBHelper.StoredProcedure("[DocumentStatusChange]", conn);
                cmd.Add("@VersionID", model.VersionID);
                cmd.Add("@Action", model.Action);
                cmd.Add("@Comments", model.Comments);
                cmd.Add("@UserID", model.UserID);
                conn.Open();
                cmd.ExecuteNonQuery();
                response.Response = model.Action == "Cancel" ? "Document Cancelled"
                                  : model.Action == "Archive" ? "Document Archived" : "Document Restored";
            }
            catch (Exception ex)
            {
                response.ErrorMessage = ex.Message;
            }
            return response;
        }

        public APIResponse DocumentActiveStatusUpdate(DocumentStatusModel model, SqlConnection conn)
        {
            var response = new APIResponse { ID = model.DocumentID };
            try
            {
                using SqlCommand cmd = DBHelper.StoredProcedure("[DocumentActiveStatusUpdate]", conn);
                cmd.Add("@DocumentID", model.DocumentID);
                cmd.Add("@IsActive", model.IsActive);
                cmd.Add("@UserID", model.UserID);
                conn.Open();
                cmd.ExecuteNonQuery();
                response.Response = model.IsActive == "Y" ? "Document Activated" : "Document Made Obsolete";
            }
            catch (Exception ex)
            {
                response.ErrorMessage = ex.Message;
            }
            return response;
        }

        //=========================== Lists / details ===========================

        public List<DocumentListModel> DocumentList(string search, int categoryID, bool approvedOnly, string isActive, SqlConnection conn)
        {
            var list = new List<DocumentListModel>();
            using SqlCommand cmd = DBHelper.StoredProcedure("[DocumentList]", conn);
            cmd.Add("@Search", string.IsNullOrWhiteSpace(search) ? null : search);
            cmd.Add("@CategoryID", categoryID);
            cmd.Add("@ApprovedOnly", approvedOnly);
            cmd.Add("@IsActive", string.IsNullOrWhiteSpace(isActive) ? null : isActive);
            conn.Open();
            using SqlDataReader r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new DocumentListModel
                {
                    DocumentID = r.Int("DocumentID"),
                    DocumentNumber = r.Str("DocumentNumber"),
                    Title = r.Str("Title"),
                    CategoryID = r.Int("CategoryID"),
                    CategoryCode = r.Str("CategoryCode"),
                    CategoryName = r.Str("CategoryName"),
                    IsActive = r.Str("IsActive"),
                    VersionID = r.NInt("VersionID"),
                    RevisionNo = r.NInt("RevisionNo"),
                    VersionStatus = r.Str("VersionStatus"),
                    OriginalFileName = r.Str("OriginalFileName"),
                    FileType = r.Str("FileType"),
                    FileSizeKB = r.NInt("FileSizeKB"),
                    EditedBy = r.Str("EditedBy"),
                    ReviewedBy = r.Str("ReviewedBy"),
                    ApprovedBy = r.Str("ApprovedBy"),
                    IssuedDate = r.NDate("IssuedDate"),
                    PendingVersionID = r.NInt("PendingVersionID"),
                    PendingRevisionNo = r.NInt("PendingRevisionNo"),
                    PendingStatus = r.Str("PendingStatus"),
                    ChangeSummary = r.Str("ChangeSummary"),
                    Department = r.Str("Department"),
                    PlantArea = r.Str("PlantArea")
                });
            }
            return list;
        }

        public DocumentDetailModel DocumentGetById(int documentID, SqlConnection conn)
        {
            var model = new DocumentDetailModel();
            try
            {
                using SqlCommand cmd = DBHelper.StoredProcedure("[DocumentGetById]", conn);
                cmd.Add("@DocumentID", documentID);
                conn.Open();
                using SqlDataReader r = cmd.ExecuteReader();
                if (!r.Read())
                {
                    model.ErrorMessage = "Document Not Found";
                    return model;
                }
                model.DocumentID = r.Int("DocumentID");
                model.DocumentNumber = r.Str("DocumentNumber");
                model.Title = r.Str("Title");
                model.CategoryID = r.Int("CategoryID");
                model.CategoryCode = r.Str("CategoryCode");
                model.CategoryName = r.Str("CategoryName");
                model.Department = r.Str("Department");
                model.PlantArea = r.Str("PlantArea");
                model.Remarks = r.Str("Remarks");
                model.IsActive = r.Str("IsActive");
                model.CreatedOn = r.NDate("CreatedOn");
                model.CreatedBy = r.Str("CreatedBy");
                if (r.NInt("VersionID") != null)
                {
                    model.CurrentVersion = new DocumentVersionModel
                    {
                        VersionID = r.Int("VersionID"),
                        RevisionNo = r.Int("RevisionNo"),
                        StatusName = r.Str("VersionStatus"),
                        OriginalFileName = r.Str("OriginalFileName"),
                        FileType = r.Str("FileType"),
                        FileSizeKB = r.NInt("FileSizeKB"),
                        ChangeSummary = r.Str("ChangeSummary"),
                        ReasonForChange = r.Str("ReasonForChange"),
                        EditedBy = r.Str("EditedBy"),
                        ReviewedBy = r.Str("ReviewedBy"),
                        ReviewedOn = r.NDate("ReviewedOn"),
                        ApprovedBy = r.Str("ApprovedBy"),
                        ApprovedOn = r.NDate("ApprovedOn"),
                        IssuedDate = r.NDate("IssuedDate")
                    };
                }

                r.NextResult();
                if (r.Read())
                {
                    model.PendingVersion = new DocumentVersionModel
                    {
                        VersionID = r.Int("VersionID"),
                        RevisionNo = r.Int("RevisionNo"),
                        StatusID = r.NInt("StatusID"),
                        StatusName = r.Str("StatusName"),
                        OriginalFileName = r.Str("OriginalFileName"),
                        FileType = r.Str("FileType"),
                        FileSizeKB = r.NInt("FileSizeKB"),
                        ChangeSummary = r.Str("ChangeSummary"),
                        ReasonForChange = r.Str("ReasonForChange"),
                        EditedBy = r.Str("EditedBy"),
                        EditedByUserID = r.NInt("EditedByUserID"),
                        SubmittedOn = r.NDate("SubmittedOn"),
                        ReviewedBy = r.Str("ReviewedBy"),
                        ReviewedOn = r.NDate("ReviewedOn"),
                        CreatedOn = r.NDate("CreatedOn")
                    };
                }
            }
            catch (Exception ex)
            {
                model.ErrorMessage = ex.Message;
            }
            return model;
        }

        public DocumentHistoryModel DocumentHistory(int documentID, SqlConnection conn)
        {
            var model = new DocumentHistoryModel();
            using SqlCommand cmd = DBHelper.StoredProcedure("[DocumentHistory]", conn);
            cmd.Add("@DocumentID", documentID);
            conn.Open();
            using SqlDataReader r = cmd.ExecuteReader();
            while (r.Read())
            {
                model.Versions.Add(new DocumentVersionModel
                {
                    VersionID = r.Int("VersionID"),
                    RevisionNo = r.Int("RevisionNo"),
                    StatusName = r.Str("StatusName"),
                    OriginalFileName = r.Str("OriginalFileName"),
                    FileType = r.Str("FileType"),
                    FileSizeKB = r.NInt("FileSizeKB"),
                    ChangeSummary = r.Str("ChangeSummary"),
                    ReasonForChange = r.Str("ReasonForChange"),
                    EditedBy = r.Str("EditedBy"),
                    CreatedOn = r.NDate("CreatedOn"),
                    SubmittedOn = r.NDate("SubmittedOn"),
                    ReviewedBy = r.Str("ReviewedBy"),
                    ReviewedOn = r.NDate("ReviewedOn"),
                    ApprovedBy = r.Str("ApprovedBy"),
                    ApprovedOn = r.NDate("ApprovedOn"),
                    IssuedDate = r.NDate("IssuedDate")
                });
            }

            r.NextResult();
            while (r.Read())
            {
                model.Log.Add(new DocumentLogModel
                {
                    LogID = r.Long("LogID"),
                    RevisionNo = r.Int("RevisionNo"),
                    ActionType = r.Str("ActionType"),
                    ApprovalLevel = r.NInt("ApprovalLevel"),
                    FromStatus = r.Str("FromStatus"),
                    ToStatus = r.Str("ToStatus"),
                    Comments = r.Str("Comments"),
                    ActionBy = r.Str("ActionBy"),
                    ActionOn = r.NDate("ActionOn")
                });
            }
            return model;
        }

        public List<PendingApprovalModel> DocumentPendingApprovals(int userID, SqlConnection conn)
        {
            var list = new List<PendingApprovalModel>();
            using SqlCommand cmd = DBHelper.StoredProcedure("[DocumentPendingApprovals]", conn);
            cmd.Add("@UserID", userID);
            conn.Open();
            using SqlDataReader r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new PendingApprovalModel
                {
                    VersionID = r.Int("VersionID"),
                    DocumentID = r.Int("DocumentID"),
                    DocumentNumber = r.Str("DocumentNumber"),
                    Title = r.Str("Title"),
                    CategoryName = r.Str("CategoryName"),
                    RevisionNo = r.Int("RevisionNo"),
                    StatusName = r.Str("StatusName"),
                    ApprovalLevel = r.NInt("ApprovalLevel"),
                    OriginalFileName = r.Str("OriginalFileName"),
                    FileType = r.Str("FileType"),
                    ChangeSummary = r.Str("ChangeSummary"),
                    EditedBy = r.Str("EditedBy"),
                    SubmittedOn = r.NDate("SubmittedOn"),
                    ReviewedBy = r.Str("ReviewedBy"),
                    ReviewedOn = r.NDate("ReviewedOn")
                });
            }
            return list;
        }

        /// <summary>Returns null when the revision does not exist.</summary>
        public DocumentFileModel DocumentVersionGetFile(int versionID, SqlConnection conn)
        {
            using SqlCommand cmd = DBHelper.StoredProcedure("[DocumentVersionGetFile]", conn);
            cmd.Add("@VersionID", versionID);
            conn.Open();
            using SqlDataReader r = cmd.ExecuteReader();
            if (!r.Read()) return null;
            return new DocumentFileModel
            {
                VersionID = r.Int("VersionID"),
                DocumentNumber = r.Str("DocumentNumber"),
                RevisionNo = r.Int("RevisionNo"),
                StatusID = r.Int("StatusID"),
                OriginalFileName = r.Str("OriginalFileName"),
                StoredFileName = r.Str("StoredFileName"),
                FilePath = r.Str("FilePath"),
                FileType = r.Str("FileType")
            };
        }
    }
}
