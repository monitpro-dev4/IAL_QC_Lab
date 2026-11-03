/* =============================================================
   Procedure : UserLogout
   Purpose   : Ends one session (sign out).
   Example   : EXEC UserLogout '<64 hex chars>';
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.UserLogout
    @TokenHash CHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE dbo.UserLoginHistory
        SET LogoutTime = GETDATE()
        WHERE TokenHash = @TokenHash AND LogoutTime IS NULL;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
