/* =============================================================
   Procedure : DocumentList
   Module    : Document Management
   Purpose   : Document list page.
               @ApprovedOnly = 1 : only documents with an approved
                                   version, showing that version
                                   (what normal users see)
               @ApprovedOnly = 0 : every document, showing its approved
                                   version or, if none yet, its latest
                                   draft (for chemists / admins)
               PendingRevisionNo / PendingStatus show a revision that
               is in progress or rejected, if any.
   Params    : @Search      matches document number or title
               @CategoryID  0 = all
               @IsActive    NULL = all, 'Y' = active (default)
   Example   : EXEC DocumentList NULL, 0, 1, 'Y';
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DocumentList
    @Search        VARCHAR(100) = NULL,
    @CategoryID    INT          = 0,
    @ApprovedOnly  BIT          = 1,
    @IsActive      CHAR(1)      = 'Y'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF LTRIM(RTRIM(@Search)) IN ('', 'null') SET @Search = NULL;

        SELECT d.DocumentID, d.DocumentNumber, d.Title,
               c.CategoryID, c.CategoryCode, c.CategoryName,
               d.IsActive,
               v.VersionID, v.RevisionNo, VersionStatus = s.StatusName,
               v.OriginalFileName, v.StoredFileName, v.FilePath, v.FileType, v.FileSizeKB,
               EditedBy   = ue.Name,
               ReviewedBy = ur.Name,
               ApprovedBy = ua.Name,
               v.IssuedDate,
               PendingVersionID  = p.VersionID,
               PendingRevisionNo = p.RevisionNo,
               PendingStatus     = ps.StatusName,
               v.ChangeSummary,                     -- "Remarks" in the list (added 2026-11-11)
               d.Department, d.PlantArea            -- added 2026-11-17
        FROM dbo.Document d
        LEFT JOIN dbo.DocumentCategory c ON c.CategoryID = d.CategoryID
        OUTER APPLY (SELECT TOP 1 x.*
                     FROM dbo.DocumentVersion x
                     WHERE x.DocumentID = d.DocumentID
                       -- full list: the latest uploaded revision; approved-only list: the current approved one
                       AND (@ApprovedOnly = 0 OR x.VersionID = d.CurrentVersionID)
                     -- ...except when the latest revision was cancelled and an approved (or archived) version
                     -- exists: that version is still the one in use, so it is shown instead
                     ORDER BY CASE WHEN d.CurrentVersionID IS NOT NULL
                                    AND (SELECT TOP 1 z.StatusID FROM dbo.DocumentVersion z
                                         WHERE z.DocumentID = d.DocumentID ORDER BY z.RevisionNo DESC) = 7
                                   THEN CASE WHEN x.VersionID = d.CurrentVersionID THEN 0 ELSE 1 END
                                   ELSE 0 END,
                              x.RevisionNo DESC) v
        LEFT JOIN dbo.DocumentStatusMaster s ON s.StatusID = v.StatusID
        LEFT JOIN dbo.UserMaster ue ON ue.UserID = v.EditedBy
        LEFT JOIN dbo.UserMaster ur ON ur.UserID = v.ReviewedBy
        LEFT JOIN dbo.UserMaster ua ON ua.UserID = v.ApprovedBy
        OUTER APPLY (SELECT TOP 1 y.VersionID, y.RevisionNo, y.StatusID
                     FROM dbo.DocumentVersion y
                     WHERE y.DocumentID = d.DocumentID
                       AND y.StatusID IN (1, 2, 3, 5)
                       AND d.CurrentVersionID IS NOT NULL
                     ORDER BY y.RevisionNo DESC) p
        LEFT JOIN dbo.DocumentStatusMaster ps ON ps.StatusID = p.StatusID
        WHERE (@ApprovedOnly = 0 OR EXISTS (SELECT 1 FROM dbo.DocumentVersion cv
                                            WHERE cv.VersionID = d.CurrentVersionID AND cv.StatusID = 4))
          AND (@IsActive IS NULL OR d.IsActive = @IsActive)
          AND (ISNULL(@CategoryID, 0) = 0 OR d.CategoryID = @CategoryID)
          AND (@Search IS NULL
               OR d.DocumentNumber LIKE '%' + @Search + '%'
               OR d.Title          LIKE '%' + @Search + '%')
        ORDER BY d.CreatedOn DESC, d.DocumentID DESC;   -- newest first
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
