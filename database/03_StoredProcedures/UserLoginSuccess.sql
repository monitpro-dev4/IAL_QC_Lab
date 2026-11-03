/* =============================================================
   Procedure : UserLoginSuccess
   Purpose   : Called after the password is verified. Clears the
               wrong-password count and lock, records the login and
               starts a session for the token (stored as its hash).
   Example   : EXEC UserLoginSuccess 1, '<64 hex chars>', '10.0.0.5', 'Chrome';
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.UserLoginSuccess
    @UserID     INT,
    @TokenHash  CHAR(64),
    @IPAddress  VARCHAR(50)  = NULL,
    @UserAgent  VARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @OwnTran BIT = 0;
    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION; SET @OwnTran = 1; END

        UPDATE dbo.UserMaster
        SET FailedLoginCount = 0, LockedUntil = NULL, LastLoginOn = GETDATE()
        WHERE UserID = @UserID AND IsActive = 'Y';

        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR ('User Not Found Or Inactive', 11, 1);
            RETURN;
        END

        INSERT INTO dbo.UserLoginHistory (UserID, TokenHash, LoginTime, IPAddress, UserAgent)
        VALUES (@UserID, @TokenHash, GETDATE(), LEFT(@IPAddress, 50), LEFT(@UserAgent, 300));

        IF @OwnTran = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @OwnTran = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
