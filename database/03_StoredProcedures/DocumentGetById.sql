/* =============================================================
   Procedure : DocumentGetById
   Module    : Document Management
   Purpose   : One document's details page.
   Returns   : Result 1 = document + its current approved version
               Result 2 = the revision in progress or rejected, if any
   Example   : EXEC DocumentGetById 1;
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DocumentGetById
    @DocumentID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT d.DocumentID, d.DocumentNumber, d.Title,
               c.CategoryID, c.CategoryCode, c.CategoryName, d.Department, d.PlantArea, d.Remarks, d.IsActive,
               d.CreatedOn, CreatedBy = uc.Name,
               v.VersionID, v.RevisionNo, VersionStatus = s.StatusName,
               v.OriginalFileName, v.StoredFileName, v.FilePath, v.FileType, v.FileSizeKB,
               v.ChangeSummary, v.ReasonForChange,
               EditedBy = ue.Name, ReviewedBy = ur.Name, v.ReviewedOn,
               ApprovedBy = ua.Name, v.ApprovedOn, v.IssuedDate
        FROM dbo.Document d
        LEFT JOIN dbo.DocumentCategory c ON c.CategoryID = d.CategoryID
        LEFT JOIN dbo.DocumentVersion v ON v.VersionID = d.CurrentVersionID
        LEFT JOIN dbo.DocumentStatusMaster s ON s.StatusID = v.StatusID
        LEFT JOIN dbo.UserMaster uc ON uc.UserID = d.CreatedBy
        LEFT JOIN dbo.UserMaster ue ON ue.UserID = v.EditedBy
        LEFT JOIN dbo.UserMaster ur ON ur.UserID = v.ReviewedBy
        LEFT JOIN dbo.UserMaster ua ON ua.UserID = v.ApprovedBy
        WHERE d.DocumentID = @DocumentID;

        SELECT v.VersionID, v.RevisionNo, v.StatusID, StatusName = s.StatusName,
               v.OriginalFileName, v.StoredFileName, v.FilePath, v.FileType, v.FileSizeKB,
               v.ChangeSummary, v.ReasonForChange, EditedBy = ue.Name, v.EditedBy AS EditedByUserID,
               v.SubmittedOn, ReviewedBy = ur.Name, v.ReviewedOn, v.CreatedOn
        FROM dbo.DocumentVersion v
        JOIN dbo.DocumentStatusMaster s ON s.StatusID = v.StatusID
        LEFT JOIN dbo.UserMaster ue ON ue.UserID = v.EditedBy
        LEFT JOIN dbo.UserMaster ur ON ur.UserID = v.ReviewedBy
        WHERE v.DocumentID = @DocumentID AND v.StatusID IN (1, 2, 3, 5);
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
