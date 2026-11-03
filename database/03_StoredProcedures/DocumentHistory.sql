/* =============================================================
   Procedure : DocumentHistory
   Module    : Document Management
   Purpose   : History page for one document.
   Returns   : Result 1 = every revision, newest first
               Result 2 = full audit trail, newest first
   Example   : EXEC DocumentHistory 1;
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DocumentHistory
    @DocumentID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT v.VersionID, v.RevisionNo, StatusName = s.StatusName,
               v.OriginalFileName, v.StoredFileName, v.FilePath, v.FileType, v.FileSizeKB,
               v.ChangeSummary,
               EditedBy = ue.Name, v.CreatedOn,
               v.SubmittedOn,
               ReviewedBy = ur.Name, v.ReviewedOn,
               ApprovedBy = ua.Name, v.ApprovedOn,
               v.IssuedDate
        FROM dbo.DocumentVersion v
        JOIN dbo.DocumentStatusMaster s ON s.StatusID = v.StatusID
        LEFT JOIN dbo.UserMaster ue ON ue.UserID = v.EditedBy
        LEFT JOIN dbo.UserMaster ur ON ur.UserID = v.ReviewedBy
        LEFT JOIN dbo.UserMaster ua ON ua.UserID = v.ApprovedBy
        WHERE v.DocumentID = @DocumentID
        ORDER BY v.RevisionNo DESC;

        SELECT l.LogID, v.RevisionNo, l.ActionType, l.ApprovalLevel,
               FromStatus = fs.StatusName, ToStatus = ts.StatusName,
               l.Comments, ActionBy = u.Name, l.ActionOn
        FROM dbo.DocumentApprovalLog l
        JOIN dbo.DocumentVersion v ON v.VersionID = l.VersionID
        LEFT JOIN dbo.DocumentStatusMaster fs ON fs.StatusID = l.FromStatusID
        JOIN dbo.DocumentStatusMaster ts ON ts.StatusID = l.ToStatusID
        JOIN dbo.UserMaster u ON u.UserID = l.ActionBy
        WHERE v.DocumentID = @DocumentID
        ORDER BY l.ActionOn DESC, l.LogID DESC;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
