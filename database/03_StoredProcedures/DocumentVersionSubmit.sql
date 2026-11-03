/* =============================================================
   Procedure : DocumentVersionSubmit
   Module    : Document Management
   Purpose   : Send a Draft revision for approval (Draft -> Submitted).
               It then appears in the Lab Supervisor's pending list.
   Who       : Lab Chemist, Lab Supervisor, Lab Manager, Administrator
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DocumentVersionSubmit
    @VersionID  INT,
    @Comments   VARCHAR(1000) = NULL,
    @UserID     INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @OwnTran BIT = 0, @StatusID TINYINT, @DocumentID INT;
    IF LTRIM(RTRIM(@Comments)) IN ('', 'null') SET @Comments = NULL;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.UserRoles ur
                       JOIN dbo.RoleMaster rm ON rm.RoleID = ur.RoleID AND rm.IsActive = 'Y'
                       JOIN dbo.UserMaster u  ON u.UserID  = ur.UserID AND u.IsActive  = 'Y'
                       WHERE ur.UserID = @UserID
                         AND rm.RoleName IN ('Lab Chemist','Lab Supervisor','Lab Manager','Administrator'))
        BEGIN
            RAISERROR ('You Do Not Have Permission To Submit Documents', 11, 1);
            RETURN;
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

        IF @StatusID <> 1
        BEGIN
            RAISERROR ('Only A Draft Revision Can Be Submitted', 11, 1);
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.Document WHERE DocumentID = @DocumentID AND IsActive = 'Y')
        BEGIN
            RAISERROR ('Document Is Inactive', 11, 1);
            RETURN;
        END

        UPDATE dbo.DocumentVersion
        SET StatusID = 2, SubmittedOn = GETDATE(), ModifiedBy = @UserID, ModifiedOn = GETDATE()
        WHERE VersionID = @VersionID;

        INSERT INTO dbo.DocumentApprovalLog (VersionID, ActionType, ApprovalLevel, FromStatusID, ToStatusID, Comments, ActionBy, ActionOn)
        VALUES (@VersionID, 'Submitted', NULL, 1, 2, @Comments, @UserID, GETDATE());

        IF @OwnTran = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @OwnTran = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
