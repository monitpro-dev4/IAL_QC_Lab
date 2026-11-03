/* =============================================================
   Procedure : UserGetByUserName
   Purpose   : Used by the backend at login. Returns the active user
               with PasswordHash (checked by the backend with BCrypt)
               and the lock / must-change flags.
               Returns NO rows for an unknown or inactive user; the
               backend then shows the same message as a wrong password,
               so nobody can find out which usernames exist.
   Returns   : Result 1 = user (0 or 1 row), Result 2 = active roles
   Example   : EXEC UserGetByUserName 'suresh';
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.UserGetByUserName
    @UserName VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @UserID INT;

        SELECT @UserID = UserID
        FROM dbo.UserMaster
        WHERE UserName = LTRIM(RTRIM(@UserName)) AND IsActive = 'Y';

        SELECT u.UserID, u.Name, u.EmployeeID, u.UserName, u.PasswordHash,
               u.EmailAddress, u.Designation, u.UserImage,
               u.MustChangePassword, u.FailedLoginCount, u.LockedUntil,
               IsLocked = CAST(CASE WHEN u.LockedUntil > GETDATE() THEN 1 ELSE 0 END AS BIT)
        FROM dbo.UserMaster u
        WHERE u.UserID = @UserID;

        SELECT rm.RoleID, rm.RoleName
        FROM dbo.UserRoles ur
        JOIN dbo.RoleMaster rm ON rm.RoleID = ur.RoleID AND rm.IsActive = 'Y'
        WHERE ur.UserID = @UserID
        ORDER BY rm.RoleName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
