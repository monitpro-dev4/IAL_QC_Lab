/* =============================================================
   Procedure : DocumentCreate
   Module    : Document Management
   Purpose   : Create a new document with its first version (Draft).
               The backend saves the file to the server folder first,
               then calls this with the file details.
   Who       : Lab Chemist, Lab Supervisor, Lab Manager, Administrator
   Params    : @RevisionNo  starting revision (default 1). For an
                            existing ISO document being loaded, pass its
                            current revision, e.g. 22.
   Example   : DECLARE @D INT, @V INT;
               EXEC DocumentCreate 'IAL-SOP-123', 'Inst Calibration', 1, 1,
                    'Inst Calibration.docx', '9f1c...docx', 'D:\IAL_QC_Files\Documents',
                    NULL, 120, 'First issue', 5, @D OUTPUT, @V OUTPUT;
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DocumentCreate
    @DocumentNumber    VARCHAR(50),
    @Title             VARCHAR(200),
    @CategoryID        INT           = NULL,   -- optional; 0 or NULL = no category
    @RevisionNo        INT           = 1,
    @OriginalFileName  VARCHAR(255),
    @StoredFileName    VARCHAR(255),
    @FilePath          VARCHAR(500),
    @FileType          VARCHAR(10)   = NULL,
    @FileSizeKB        INT           = NULL,
    @ChangeSummary     VARCHAR(500)  = NULL,
    @UserID            INT,
    @NewDocumentID     INT OUTPUT,
    @NewVersionID      INT OUTPUT,
    @Department        VARCHAR(100)  = NULL,   -- added 2026-11-11
    @PlantArea         VARCHAR(100)  = NULL,   -- added 2026-11-11
    @Remarks           VARCHAR(500)  = NULL    -- added 2026-11-17: the document's remarks
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @OwnTran BIT = 0;

    SET @DocumentNumber = UPPER(LTRIM(RTRIM(@DocumentNumber)));
    SET @Title          = LTRIM(RTRIM(@Title));
    IF LTRIM(RTRIM(@ChangeSummary)) = 'null' SET @ChangeSummary = NULL;
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

        IF ISNULL(@DocumentNumber, '') = '' OR ISNULL(@Title, '') = ''
        BEGIN
            RAISERROR ('Document Number And Title Are Required', 11, 1);
            RETURN;
        END

        IF ISNULL(@OriginalFileName, '') = '' OR ISNULL(@StoredFileName, '') = '' OR ISNULL(@FilePath, '') = ''
        BEGIN
            RAISERROR ('File Details Are Required', 11, 1);
            RETURN;
        END

        IF ISNULL(@RevisionNo, -1) < 0
        BEGIN
            RAISERROR ('Revision Number Must Be 0 Or More', 11, 1);
            RETURN;
        END

        IF @CategoryID = 0 SET @CategoryID = NULL;

        IF @CategoryID IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.DocumentCategory WHERE CategoryID = @CategoryID AND IsActive = 'Y')
        BEGIN
            RAISERROR ('Invalid Category Selected', 11, 1);
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM dbo.Document WHERE DocumentNumber = @DocumentNumber)
        BEGIN
            RAISERROR ('Document Number Already Exists', 11, 1);
            RETURN;
        END

        IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION; SET @OwnTran = 1; END

        INSERT INTO dbo.Document (DocumentNumber, Title, CategoryID, Department, PlantArea, Remarks, IsActive, CreatedBy, CreatedOn)
        VALUES (@DocumentNumber, @Title, @CategoryID, NULLIF(LTRIM(RTRIM(@Department)), ''),
                NULLIF(LTRIM(RTRIM(@PlantArea)), ''), NULLIF(LTRIM(RTRIM(@Remarks)), ''), 'Y', @UserID, GETDATE());
        SET @NewDocumentID = SCOPE_IDENTITY();

        INSERT INTO dbo.DocumentVersion (DocumentID, RevisionNo, OriginalFileName, StoredFileName, FilePath,
                                         FileType, FileSizeKB, ChangeSummary, StatusID, EditedBy, CreatedBy, CreatedOn)
        VALUES (@NewDocumentID, @RevisionNo, @OriginalFileName, @StoredFileName, @FilePath,
                @FileType, @FileSizeKB, @ChangeSummary, 1, @UserID, @UserID, GETDATE());
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
