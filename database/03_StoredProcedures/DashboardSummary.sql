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
               Result 4 = last 6 months: uploaded / approved / rejected per month
                          (employees: approved only)           -- added 2026-11-18
               Result 5 = average approval times in hours        -- added 2026-11-18
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
            ApprovedDocuments = (SELECT COUNT(*) FROM dbo.Document d
                                 JOIN dbo.DocumentVersion cv ON cv.VersionID = d.CurrentVersionID AND cv.StatusID = 4
                                 WHERE d.IsActive = 'Y'),
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

        -- 4. Last 6 months (this month included): revisions uploaded, final approvals, rejections
        DECLARE @From DATE = DATEADD(MONTH, -5, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1));
        ;WITH m AS (
            SELECT MonthStart = @From
            UNION ALL
            SELECT DATEADD(MONTH, 1, MonthStart) FROM m WHERE MonthStart < DATEADD(MONTH, 5, @From)
        )
        SELECT m.MonthStart,
               Uploaded = CASE WHEN @CanViewDrafts = 1 THEN
                          (SELECT COUNT(*) FROM dbo.DocumentVersion v JOIN dbo.Document d ON d.DocumentID = v.DocumentID
                           WHERE d.IsActive = 'Y' AND v.CreatedOn >= m.MonthStart AND v.CreatedOn < DATEADD(MONTH, 1, m.MonthStart)) ELSE 0 END,
               Approved = (SELECT COUNT(*) FROM dbo.DocumentApprovalLog l
                           JOIN dbo.DocumentVersion v ON v.VersionID = l.VersionID
                           JOIN dbo.Document d ON d.DocumentID = v.DocumentID AND d.IsActive = 'Y'
                           WHERE l.ActionType = 'Approved' AND l.ApprovalLevel = 2
                             AND l.ActionOn >= m.MonthStart AND l.ActionOn < DATEADD(MONTH, 1, m.MonthStart)),
               Rejected = CASE WHEN @CanViewDrafts = 1 THEN
                          (SELECT COUNT(*) FROM dbo.DocumentApprovalLog l
                           JOIN dbo.DocumentVersion v ON v.VersionID = l.VersionID
                           JOIN dbo.Document d ON d.DocumentID = v.DocumentID AND d.IsActive = 'Y'
                           WHERE l.ActionType = 'Rejected'
                             AND l.ActionOn >= m.MonthStart AND l.ActionOn < DATEADD(MONTH, 1, m.MonthStart)) ELSE 0 END
        FROM m
        ORDER BY m.MonthStart;

        -- 5. Average approval times (hours) over every revision that reached final approval
        SELECT ApprovedRevisions = COUNT(*),
               AvgTotalHours     = AVG(CAST(DATEDIFF(MINUTE, ISNULL(v.SubmittedOn, v.CreatedOn), v.ApprovedOn) AS DECIMAL(12, 2)) / 60),
               AvgReviewHours    = AVG(CASE WHEN v.ReviewedOn IS NOT NULL
                                            THEN CAST(DATEDIFF(MINUTE, ISNULL(v.SubmittedOn, v.CreatedOn), v.ReviewedOn) AS DECIMAL(12, 2)) / 60 END),
               AvgManagerHours   = AVG(CASE WHEN v.ReviewedOn IS NOT NULL
                                            THEN CAST(DATEDIFF(MINUTE, v.ReviewedOn, v.ApprovedOn) AS DECIMAL(12, 2)) / 60 END)
        FROM dbo.DocumentVersion v
        JOIN dbo.Document d ON d.DocumentID = v.DocumentID AND d.IsActive = 'Y'
        WHERE v.ApprovedOn IS NOT NULL;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
