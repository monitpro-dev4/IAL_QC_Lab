/* =============================================================
   Procedure : UsersGet
   Purpose   : User list for the User Management page
   Params    : @Search    matches name, username, employee ID or email
               @RoleID    0 = all roles
               @IsActive  NULL = all, 'Y' = active, 'N' = inactive
   Example   : EXEC UsersGet NULL, 0, 'Y';
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.UsersGet
    @Search    VARCHAR(100) = NULL,
    @RoleID    INT          = 0,
    @IsActive  CHAR(1)      = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF LTRIM(RTRIM(@Search)) IN ('', 'null') SET @Search = NULL;

        SELECT u.UserID, u.Name, u.EmployeeID, u.UserName, u.EmailAddress, u.MobileNo,
               u.Designation, u.UserImage, u.IsActive, u.CreatedOn, u.ModifiedOn,
               RoleIDs   = (SELECT STRING_AGG(CAST(ur.RoleID AS VARCHAR(10)), ',')
                                   WITHIN GROUP (ORDER BY ur.RoleID)
                            FROM dbo.UserRoles ur WHERE ur.UserID = u.UserID),
               RoleNames = (SELECT STRING_AGG(rm.RoleName, ', ')
                                   WITHIN GROUP (ORDER BY rm.RoleName)
                            FROM dbo.UserRoles ur
                            JOIN dbo.RoleMaster rm ON rm.RoleID = ur.RoleID
                            WHERE ur.UserID = u.UserID)
        FROM dbo.UserMaster u
        WHERE (@IsActive IS NULL OR u.IsActive = @IsActive)
          AND (@Search IS NULL
               OR u.Name         LIKE '%' + @Search + '%'
               OR u.UserName     LIKE '%' + @Search + '%'
               OR u.EmployeeID   LIKE '%' + @Search + '%'
               OR u.EmailAddress LIKE '%' + @Search + '%')
          AND (ISNULL(@RoleID, 0) = 0
               OR EXISTS (SELECT 1 FROM dbo.UserRoles ur
                          WHERE ur.UserID = u.UserID AND ur.RoleID = @RoleID))
        ORDER BY u.CreatedOn DESC, u.UserID DESC;   -- newest first
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
