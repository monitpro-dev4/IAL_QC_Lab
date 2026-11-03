/* =============================================================
   Procedure : UserPasswordUpdate
   Purpose   : Saves a new password hash (BCrypt, made by the backend).
               Used for: the user changing their own password
               (@MustChangePassword = 0, keeps their current session),
               and the admin resetting it (also 0 since 2026-10-14_002).
               Every other open session of the user is ended, so an
               old or stolen login stops working.
               Also clears any lock.
   Example   : EXEC UserPasswordUpdate 2, '$2a$11$...', 1, 1, NULL;
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.UserPasswordUpdate
    @UserID             INT,
    @PasswordHash       NVARCHAR(256),
    @MustChangePassword BIT,
    @ModifiedBy         INT,
    @KeepTokenHash      CHAR(64) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @OwnTran BIT = 0;
    BEGIN TRY
        IF ISNULL(@PasswordHash, '') = ''
        BEGIN
            RAISERROR ('Password Is Required', 11, 1);
            RETURN;
        END

        IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION; SET @OwnTran = 1; END

        UPDATE dbo.UserMaster
        SET PasswordHash       = @PasswordHash,
            MustChangePassword = @MustChangePassword,
            FailedLoginCount   = 0,
            LockedUntil        = NULL,
            ModifiedBy         = @ModifiedBy,
            ModifiedOn         = GETDATE()
        WHERE UserID = @UserID;

        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR ('User Not Found', 11, 1);
            RETURN;
        END

        UPDATE dbo.UserLoginHistory
        SET LogoutTime = GETDATE()
        WHERE UserID = @UserID AND LogoutTime IS NULL
          AND (@KeepTokenHash IS NULL OR TokenHash <> @KeepTokenHash);

        IF @OwnTran = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @OwnTran = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
