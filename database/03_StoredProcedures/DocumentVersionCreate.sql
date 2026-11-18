/* =============================================================
   Procedure : DocumentVersionCreate
   Module    : Document Management
   Purpose   : Upload a new revision of an existing document.
               The revision number is the next one automatically.
   Rules     : Allowed at any time. A revision that is not approved yet
               (Draft / Submitted / Supervisor Approved / Rejected) is not
               overwritten: it is marked Superseded and kept in the history
               with its file, and the new revision goes for approval.
   Changed   : 2026-10-26 - revisions allowed at any time, older ones kept
               2026-10-26 - optional @Title changes the document title
   Who       : Lab Chemist, Lab Supervisor, Lab Manager, Administrator
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DocumentVersionCreate
    @DocumentID        INT,
    @OriginalFileName  VARCHAR(255),
    @StoredFileName    VARCHAR(255),
    @FilePath          VARCHAR(500),
    @FileType          VARCHAR(10)   = NULL,
    @FileSizeKB        INT           = NULL,
    @ChangeSummary     VARCHAR(500)  = NULL,
    @UserID            INT,
    @NewVersionID      INT OUTPUT,
    @Title             VARCHAR(200)  = NULL,   -- NULL / empty = keep the current title
    @ReasonForChange   VARCHAR(500)  = NULL    -- added 2026-11-11
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @OwnTran BIT = 0, @NextRevision INT;

    IF LTRIM(RTRIM(@ChangeSummary)) = 'null' SET @ChangeSummary = NULL;
    IF LTRIM(RTRIM(@Title)) IN ('', 'null') SET @Title = NULL;
    SET @Title = LTRIM(RTRIM(@Title));
    IF LTRIM(RTRIM(@FileType))      = 'null' SET @FileType      = NULL;
    IF @FileType IS NULL AND CHARINDEX('.', @OriginalFileName) > 0
        SET @FileType = LOWER(REVERSE(LEFT(REVERSE(@OriginalFileName), CHARINDEX('.', REVERSE(@OriginalFileName)) - 1)));

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.UserRoles ur
                       JOIN dbo.RoleMaster rm ON rm.RoleID = ur.RoleID AND rm.IsActive = 'Y'
                       JOIN dbo.UserMaster u  ON u.UserID  = ur.UserID AND u.IsActive  = 'Y'
                       WHERE ur.UserID = @UserID
                         AND rm.RoleName IN ('Lab Chemist','Lab Supervisor','Lab Manager','Administrator'))
        BEGIN
            RAISERROR ('You Do Not Have Permission To Add Documents', 11, 1);
            RETURN;
        END

        IF ISNULL(@OriginalFileName, '') = '' OR ISNULL(@StoredFileName, '') = '' OR ISNULL(@FilePath, '') = ''
        BEGIN
            RAISERROR ('File Details Are Required', 11, 1);
            RETURN;
        END

        IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION; SET @OwnTran = 1; END

        IF NOT EXISTS (SELECT 1 FROM dbo.Document WITH (UPDLOCK, HOLDLOCK)
                       WHERE DocumentID = @DocumentID AND IsActive = 'Y')
        BEGIN
            RAISERROR ('Document Not Found Or Inactive', 11, 1);
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM dbo.Document d JOIN dbo.DocumentVersion cv ON cv.VersionID = d.CurrentVersionID
                   WHERE d.DocumentID = @DocumentID AND cv.StatusID = 8)
        BEGIN
            RAISERROR ('This Document Is Archived - Restore It Before Uploading A New Revision', 11, 1);
            RETURN;
        END

        -- The revision still in the approval flow (or rejected) is kept in history as Superseded
        INSERT INTO dbo.DocumentApprovalLog (VersionID, ActionType, ApprovalLevel, FromStatusID, ToStatusID, Comments, ActionBy, ActionOn)
        SELECT VersionID, 'Superseded', NULL, StatusID, 6, 'Replaced by a newer revision', @UserID, GETDATE()
        FROM dbo.DocumentVersion
        WHERE DocumentID = @DocumentID AND StatusID IN (1, 2, 3, 5);

        UPDATE dbo.DocumentVersion
        SET StatusID = 6, ModifiedBy = @UserID, ModifiedOn = GETDATE()
        WHERE DocumentID = @DocumentID AND StatusID IN (1, 2, 3, 5);

        IF @Title IS NOT NULL
            UPDATE dbo.Document
            SET Title = @Title, ModifiedBy = @UserID, ModifiedOn = GETDATE()
            WHERE DocumentID = @DocumentID AND Title <> @Title;

        SELECT @NextRevision = ISNULL(MAX(RevisionNo), 0) + 1
        FROM dbo.DocumentVersion WHERE DocumentID = @DocumentID;

        INSERT INTO dbo.DocumentVersion (DocumentID, RevisionNo, OriginalFileName, StoredFileName, FilePath,
                                         FileType, FileSizeKB, ChangeSummary, ReasonForChange, StatusID, EditedBy, CreatedBy, CreatedOn)
        VALUES (@DocumentID, @NextRevision, @OriginalFileName, @StoredFileName, @FilePath,
                @FileType, @FileSizeKB, @ChangeSummary, NULLIF(LTRIM(RTRIM(@ReasonForChange)), ''), 1, @UserID, @UserID, GETDATE());
        SET @NewVersionID = SCOPE_IDENTITY();

        INSERT INTO dbo.DocumentApprovalLog (VersionID, ActionType, ApprovalLevel, FromStatusID, ToStatusID, Comments, ActionBy, ActionOn)
        VALUES (@NewVersionID, 'Created', NULL, NULL, 1, @ChangeSummary, @UserID, GETDATE());

        IF @OwnTran = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @OwnTran = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
