/* =============================================================
   Procedure : DocumentVersionUpdate
   Module    : Document Management
   Purpose   : Change a Draft or Rejected revision before (re)submitting:
               replace the file, the change summary, or the title.
               A Rejected revision goes back to Draft.
               (Uploading a new file from the screens now creates a new
               revision instead - see DocumentVersionCreate.)
   Params    : File fields NULL = keep the current file
               @Title NULL = keep the current title
   Who       : Lab Chemist, Lab Supervisor, Lab Manager, Administrator
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DocumentVersionUpdate
    @VersionID         INT,
    @Title             VARCHAR(200)  = NULL,
    @OriginalFileName  VARCHAR(255)  = NULL,
    @StoredFileName    VARCHAR(255)  = NULL,
    @FilePath          VARCHAR(500)  = NULL,
    @FileType          VARCHAR(10)   = NULL,
    @FileSizeKB        INT           = NULL,
    @ChangeSummary     VARCHAR(500)  = NULL,
    @UserID            INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @OwnTran BIT = 0, @StatusID TINYINT, @DocumentID INT, @NewFile BIT = 0;

    IF LTRIM(RTRIM(@Title))            IN ('', 'null') SET @Title            = NULL;
    IF LTRIM(RTRIM(@OriginalFileName)) IN ('', 'null') SET @OriginalFileName = NULL;
    IF LTRIM(RTRIM(@StoredFileName))   IN ('', 'null') SET @StoredFileName   = NULL;
    IF LTRIM(RTRIM(@FilePath))         IN ('', 'null') SET @FilePath         = NULL;
    IF LTRIM(RTRIM(@FileType))         IN ('', 'null') SET @FileType         = NULL;
    IF LTRIM(RTRIM(@ChangeSummary))    = 'null'        SET @ChangeSummary    = NULL;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.UserRoles ur
                       JOIN dbo.RoleMaster rm ON rm.RoleID = ur.RoleID AND rm.IsActive = 'Y'
                       JOIN dbo.UserMaster u  ON u.UserID  = ur.UserID AND u.IsActive  = 'Y'
                       WHERE ur.UserID = @UserID
                         AND rm.RoleName IN ('Lab Chemist','Lab Supervisor','Lab Manager','Administrator'))
        BEGIN
            RAISERROR ('You Do Not Have Permission To Edit Documents', 11, 1);
            RETURN;
        END

        -- A new file needs all three file details
        IF COALESCE(@OriginalFileName, @StoredFileName, @FilePath) IS NOT NULL
        BEGIN
            IF @OriginalFileName IS NULL OR @StoredFileName IS NULL OR @FilePath IS NULL
            BEGIN
                RAISERROR ('File Details Are Incomplete', 11, 1);
                RETURN;
            END
            SET @NewFile = 1;
            IF @FileType IS NULL AND CHARINDEX('.', @OriginalFileName) > 0
                SET @FileType = LOWER(REVERSE(LEFT(REVERSE(@OriginalFileName), CHARINDEX('.', REVERSE(@OriginalFileName)) - 1)));
        END

        IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION; SET @OwnTran = 1; END

        SELECT @StatusID = v.StatusID, @DocumentID = v.DocumentID
        FROM dbo.DocumentVersion v WITH (UPDLOCK, HOLDLOCK)
        WHERE v.VersionID = @VersionID;

        IF @StatusID IS NULL
        BEGIN
            RAISERROR ('Document Version Not Found', 11, 1);
            RETURN;
        END

        IF @StatusID NOT IN (1, 5)
        BEGIN
            RAISERROR ('Only A Draft Or Rejected Revision Can Be Changed', 11, 1);
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.Document WHERE DocumentID = @DocumentID AND IsActive = 'Y')
        BEGIN
            RAISERROR ('Document Is Inactive', 11, 1);
            RETURN;
        END

        -- Reopening a rejected revision: blocked if another revision is already in progress
        IF @StatusID = 5 AND EXISTS (SELECT 1 FROM dbo.DocumentVersion
                                     WHERE DocumentID = @DocumentID AND StatusID IN (1, 2, 3) AND VersionID <> @VersionID)
        BEGIN
            RAISERROR ('Another Revision Of This Document Is Already In Progress', 11, 1);
            RETURN;
        END

        UPDATE dbo.DocumentVersion
        SET OriginalFileName = CASE WHEN @NewFile = 1 THEN @OriginalFileName ELSE OriginalFileName END,
            StoredFileName   = CASE WHEN @NewFile = 1 THEN @StoredFileName   ELSE StoredFileName   END,
            FilePath         = CASE WHEN @NewFile = 1 THEN @FilePath         ELSE FilePath         END,
            FileType         = CASE WHEN @NewFile = 1 THEN @FileType         ELSE FileType         END,
            FileSizeKB       = CASE WHEN @NewFile = 1 THEN @FileSizeKB       ELSE FileSizeKB       END,
            ChangeSummary    = ISNULL(@ChangeSummary, ChangeSummary),
            EditedBy         = @UserID,
            StatusID         = 1,
            SubmittedOn      = NULL,
            ReviewedBy       = NULL,
            ReviewedOn       = NULL,
            ModifiedBy       = @UserID,
            ModifiedOn       = GETDATE()
        WHERE VersionID = @VersionID;

        IF @Title IS NOT NULL
            UPDATE dbo.Document
            SET Title = @Title, ModifiedBy = @UserID, ModifiedOn = GETDATE()
            WHERE DocumentID = @DocumentID;

        INSERT INTO dbo.DocumentApprovalLog (VersionID, ActionType, ApprovalLevel, FromStatusID, ToStatusID, Comments, ActionBy, ActionOn)
        VALUES (@VersionID, 'Updated', NULL, @StatusID, 1, @ChangeSummary, @UserID, GETDATE());

        IF @OwnTran = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @OwnTran = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
