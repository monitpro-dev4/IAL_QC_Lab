/* =============================================================
   Procedure : UserLoginFailed
   Purpose   : Called after a wrong password. After 5 wrong passwords
               in a row the account is locked for 15 minutes.
               Unknown usernames are ignored (nothing to update).
   Returns   : LockedUntil (NULL if not locked)
   Example   : EXEC UserLoginFailed 'suresh';
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.UserLoginFailed
    @UserName VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @MaxAttempts INT = 5, @LockMinutes INT = 15;

        UPDATE dbo.UserMaster
        SET FailedLoginCount = CASE WHEN FailedLoginCount + 1 >= @MaxAttempts THEN 0 ELSE FailedLoginCount + 1 END,
            LockedUntil      = CASE WHEN FailedLoginCount + 1 >= @MaxAttempts
                                    THEN DATEADD(MINUTE, @LockMinutes, GETDATE()) ELSE LockedUntil END
        WHERE UserName = LTRIM(RTRIM(@UserName)) AND IsActive = 'Y';

        SELECT LockedUntil = (SELECT LockedUntil FROM dbo.UserMaster
                              WHERE UserName = LTRIM(RTRIM(@UserName)) AND LockedUntil > GETDATE());
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
