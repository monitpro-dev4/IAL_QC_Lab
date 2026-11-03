/* =============================================================
   Procedure : DashboardSummary
   Module    : Dashboard (home page)
   Purpose   : Numbers and lists for the signed-in user's home page.
   Params    : @UserID         the signed-in user (from the login token)
               @CanViewDrafts  1 for document staff (chemist, supervisor,
                               manager, QA, admin); 0 = employees, who only
                               see approved documents and approvals
   Returns   : Result 1 = counts (one row)
               Result 2 = approved documents per category
               Result 3 = recent activity (latest 10)
   Example   : EXEC DashboardSummary 12, 1;
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DashboardSummary
    @UserID        INT,
    @CanViewDrafts BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @IsSupervisor BIT = 0, @IsManager BIT = 0;
        SELECT @IsSupervisor = MAX(CASE WHEN rm.RoleName = 'Lab Supervisor' THEN 1 ELSE 0 END),
               @IsManager    = MAX(CASE WHEN rm.RoleName = 'Lab Manager'    THEN 1 ELSE 0 END)
        FROM dbo.UserRoles ur
        JOIN dbo.RoleMaster rm ON rm.RoleID = ur.RoleID AND rm.IsActive = 'Y'
        WHERE ur.UserID = @UserID;

        -- 1. Counts (active documents only)
        SELECT
            ApprovedDocuments = (SELECT COUNT(*) FROM dbo.Document
                                 WHERE IsActive = 'Y' AND CurrentVersionID IS NOT NULL),
            InReview          = CASE WHEN @CanViewDrafts = 1 THEN
                                (SELECT COUNT(*) FROM dbo.DocumentVersion v JOIN dbo.Document d ON d.DocumentID = v.DocumentID
                                 WHERE d.IsActive = 'Y' AND v.StatusID IN (2, 3)) ELSE 0 END,
            Drafts            = CASE WHEN @CanViewDrafts = 1 THEN
                                (SELECT COUNT(*) FROM dbo.DocumentVersion v JOIN dbo.Document d ON d.DocumentID = v.DocumentID
                                 WHERE d.IsActive = 'Y' AND v.StatusID = 1) ELSE 0 END,
            Rejected          = CASE WHEN @CanViewDrafts = 1 THEN
                                (SELECT COUNT(*) FROM dbo.DocumentVersion v JOIN dbo.Document d ON d.DocumentID = v.DocumentID
                                 WHERE d.IsActive = 'Y' AND v.StatusID = 5) ELSE 0 END,
            WaitingForMe      = (SELECT COUNT(*) FROM dbo.DocumentVersion v JOIN dbo.Document d ON d.DocumentID = v.DocumentID
                                 WHERE d.IsActive = 'Y'
                                   AND ((v.StatusID = 2 AND ISNULL(@IsSupervisor, 0) = 1)
                                     OR (v.StatusID = 3 AND ISNULL(@IsManager, 0) = 1))),
            MyOpenRevisions   = (SELECT COUNT(*) FROM dbo.DocumentVersion v JOIN dbo.Document d ON d.DocumentID = v.DocumentID
                                 WHERE d.IsActive = 'Y' AND v.EditedBy = @UserID AND v.StatusID IN (1, 2, 3, 5)),
            MyRejected        = (SELECT COUNT(*) FROM dbo.DocumentVersion v JOIN dbo.Document d ON d.DocumentID = v.DocumentID
                                 WHERE d.IsActive = 'Y' AND v.EditedBy = @UserID AND v.StatusID = 5),
            ApprovedLast30Days = (SELECT COUNT(*) FROM dbo.DocumentVersion v JOIN dbo.Document d ON d.DocumentID = v.DocumentID
                                  WHERE d.IsActive = 'Y' AND v.StatusID IN (4, 6) AND v.ApprovedOn >= DATEADD(DAY, -30, GETDATE()));

        -- 2. Approved documents per category
        SELECT c.CategoryID, c.CategoryCode, c.CategoryName,
               Documents = COUNT(d.DocumentID)
        FROM dbo.DocumentCategory c
        LEFT JOIN dbo.Document d ON d.CategoryID = c.CategoryID AND d.IsActive = 'Y' AND d.CurrentVersionID IS NOT NULL
        WHERE c.IsActive = 'Y'
        GROUP BY c.CategoryID, c.CategoryCode, c.CategoryName
        ORDER BY Documents DESC, c.CategoryName;

        -- 3. Recent activity (employees: final approvals only)
        SELECT TOP (10) l.LogID, d.DocumentID, d.DocumentNumber, d.Title, v.RevisionNo,
               l.ActionType, l.ApprovalLevel, ActionBy = u.Name, l.ActionOn
        FROM dbo.DocumentApprovalLog l
        JOIN dbo.DocumentVersion v ON v.VersionID = l.VersionID
        JOIN dbo.Document d ON d.DocumentID = v.DocumentID AND d.IsActive = 'Y'
        JOIN dbo.UserMaster u ON u.UserID = l.ActionBy
        WHERE @CanViewDrafts = 1 OR (l.ActionType = 'Approved' AND l.ApprovalLevel = 2)
        ORDER BY l.ActionOn DESC, l.LogID DESC;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
