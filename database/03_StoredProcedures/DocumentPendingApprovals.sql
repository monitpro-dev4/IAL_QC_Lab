/* =============================================================
   Procedure : DocumentPendingApprovals
   Module    : Document Management
   Purpose   : "Waiting for my approval" list for the logged-in user.
               Lab Supervisor sees Submitted revisions (level 1),
               Lab Manager sees Supervisor Approved revisions (level 2).
               Includes revisions the user uploaded themselves (self-approval allowed).
   Example   : EXEC DocumentPendingApprovals 3;
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DocumentPendingApprovals
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @IsSupervisor BIT = 0, @IsManager BIT = 0;

        SELECT @IsSupervisor = MAX(CASE WHEN rm.RoleName = 'Lab Supervisor' THEN 1 ELSE 0 END),
               @IsManager    = MAX(CASE WHEN rm.RoleName = 'Lab Manager'    THEN 1 ELSE 0 END)
        FROM dbo.UserRoles ur
        JOIN dbo.RoleMaster rm ON rm.RoleID = ur.RoleID AND rm.IsActive = 'Y'
        JOIN dbo.UserMaster u  ON u.UserID  = ur.UserID AND u.IsActive  = 'Y'
        WHERE ur.UserID = @UserID;

        SELECT v.VersionID, d.DocumentID, d.DocumentNumber, d.Title, c.CategoryName,
               v.RevisionNo, StatusName = s.StatusName,
               ApprovalLevel = CASE v.StatusID WHEN 2 THEN 1 WHEN 3 THEN 2 END,
               v.OriginalFileName, v.StoredFileName, v.FilePath, v.FileType,
               v.ChangeSummary,
               EditedBy = ue.Name, v.SubmittedOn,
               ReviewedBy = ur.Name, v.ReviewedOn
        FROM dbo.DocumentVersion v
        JOIN dbo.Document d ON d.DocumentID = v.DocumentID AND d.IsActive = 'Y'
        LEFT JOIN dbo.DocumentCategory c ON c.CategoryID = d.CategoryID
        JOIN dbo.DocumentStatusMaster s ON s.StatusID = v.StatusID
        LEFT JOIN dbo.UserMaster ue ON ue.UserID = v.EditedBy
        LEFT JOIN dbo.UserMaster ur ON ur.UserID = v.ReviewedBy
        WHERE (   (v.StatusID = 2 AND ISNULL(@IsSupervisor, 0) = 1)
               OR (v.StatusID = 3 AND ISNULL(@IsManager, 0)    = 1))
        ORDER BY v.SubmittedOn;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
