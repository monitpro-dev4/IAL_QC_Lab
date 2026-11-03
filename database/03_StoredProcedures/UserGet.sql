/* =============================================================
   Procedure : UserGet
   Purpose   : One user's details for the edit form
   Returns   : Result 1 = user, Result 2 = the user's roles
   Example   : EXEC UserGet 1;
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.UserGet
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT u.UserID, u.Name, u.EmployeeID, u.UserName, u.EmailAddress, u.MobileNo,
               u.Designation, u.UserImage, u.IsActive,
               u.CreatedBy, u.CreatedOn, u.ModifiedBy, u.ModifiedOn
        FROM dbo.UserMaster u
        WHERE u.UserID = @UserID;

        SELECT rm.RoleID, rm.RoleName
        FROM dbo.UserRoles ur
        JOIN dbo.RoleMaster rm ON rm.RoleID = ur.RoleID
        WHERE ur.UserID = @UserID
        ORDER BY rm.RoleName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
