/* =============================================================
   Procedure : UserSessionValidate
   Purpose   : Checked on every API request. Returns the signed-in
               user for a token hash if the session is still open and
               the user is still active; no rows otherwise.
               Roles come back as one text value separated by "|".
   Example   : EXEC UserSessionValidate '<64 hex chars>';
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.UserSessionValidate
    @TokenHash CHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT u.UserID, u.Name, u.UserName, u.MustChangePassword,
               Roles = (SELECT STRING_AGG(rm.RoleName, '|')
                        FROM dbo.UserRoles ur
                        JOIN dbo.RoleMaster rm ON rm.RoleID = ur.RoleID AND rm.IsActive = 'Y'
                        WHERE ur.UserID = u.UserID)
        FROM dbo.UserLoginHistory h
        JOIN dbo.UserMaster u ON u.UserID = h.UserID AND u.IsActive = 'Y'
        WHERE h.TokenHash = @TokenHash AND h.LogoutTime IS NULL;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
