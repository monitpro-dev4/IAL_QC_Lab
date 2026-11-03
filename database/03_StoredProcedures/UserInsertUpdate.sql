/* =============================================================
   Procedure : UserInsertUpdate
   Purpose   : Add a user (@UserID = 0) or update one, and set
               the user's roles, all in one transaction.
   Params    : @RoleIDs      comma-separated RoleIDs, e.g. '3,5'
                             (replaces the user's current roles)
               @PasswordHash required for a new user (BCrypt hash from the backend);
                             NULL on update = keep current password
   Example   : DECLARE @ID INT;
               EXEC UserInsertUpdate 0, 'Suresh K', 'E1001', 'suresh',
                    NULL, 'suresh@ial.com', NULL, 'Chemist', NULL,
                    'Y', '5', 1, @ID OUTPUT;
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.UserInsertUpdate
    @UserID        INT,
    @Name          VARCHAR(100),
    @EmployeeID    VARCHAR(50),
    @UserName      VARCHAR(50),
    @PasswordHash  NVARCHAR(256) = NULL,
    @EmailAddress  VARCHAR(100)  = NULL,
    @MobileNo      VARCHAR(15)   = NULL,
    @Designation   VARCHAR(100)  = NULL,
    @UserImage     VARCHAR(200)  = NULL,
    @IsActive      CHAR(1)       = 'Y',
    @RoleIDs       VARCHAR(200),
    @CreatedBy     INT,
    @NewUserID     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Only commit / roll back a transaction this procedure started,
    -- so a caller's own transaction is never cancelled by mistake.
    DECLARE @OwnTran BIT = 0;

    -- The frontend sometimes sends the text 'null'; treat it as NULL
    IF LTRIM(RTRIM(@EmailAddress)) = 'null' SET @EmailAddress = NULL;
    IF LTRIM(RTRIM(@MobileNo))     = 'null' SET @MobileNo     = NULL;
    IF LTRIM(RTRIM(@Designation))  = 'null' SET @Designation  = NULL;
    IF LTRIM(RTRIM(@UserImage))    = 'null' SET @UserImage    = NULL;

    BEGIN TRY

        IF EXISTS (SELECT 1 FROM dbo.UserMaster
                   WHERE UserName = @UserName AND (@UserID = 0 OR UserID <> @UserID))
        BEGIN
            RAISERROR ('Username Already Exists', 11, 1);
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM dbo.UserMaster
                   WHERE EmployeeID = @EmployeeID AND (@UserID = 0 OR UserID <> @UserID))
        BEGIN
            RAISERROR ('Employee ID Already Exists', 11, 1);
            RETURN;
        END

        IF @UserID = 0 AND ISNULL(@PasswordHash, '') = ''
        BEGIN
            RAISERROR ('A Password Is Required For A New User', 11, 1);
            RETURN;
        END

        IF @UserID > 0 AND NOT EXISTS (SELECT 1 FROM dbo.UserMaster WHERE UserID = @UserID)
        BEGIN
            RAISERROR ('User Not Found', 11, 1);
            RETURN;
        END

        -- Roles: at least one, and every ID must be an active role
        DECLARE @Roles TABLE (RoleID INT PRIMARY KEY);
        INSERT INTO @Roles (RoleID)
        SELECT DISTINCT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
        FROM STRING_SPLIT(ISNULL(@RoleIDs, ''), ',')
        WHERE LTRIM(RTRIM(value)) <> ''
          AND TRY_CAST(LTRIM(RTRIM(value)) AS INT) > 0;

        IF NOT EXISTS (SELECT 1 FROM @Roles)
        BEGIN
            RAISERROR ('At Least One Role Is Required', 11, 1);
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM @Roles r
                   LEFT JOIN dbo.RoleMaster rm ON rm.RoleID = r.RoleID AND rm.IsActive = 'Y'
                   WHERE rm.RoleID IS NULL)
        BEGIN
            RAISERROR ('Invalid Role Selected', 11, 1);
            RETURN;
        END

        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @OwnTran = 1;
        END

        IF @UserID > 0
        BEGIN
            UPDATE dbo.UserMaster
            SET Name         = @Name,
                EmployeeID   = @EmployeeID,
                UserName     = @UserName,
                PasswordHash = ISNULL(@PasswordHash, PasswordHash),
                EmailAddress = @EmailAddress,
                MobileNo     = @MobileNo,
                Designation  = @Designation,
                UserImage    = @UserImage,
                IsActive     = @IsActive,
                ModifiedBy   = @CreatedBy,
                ModifiedOn   = GETDATE()
            WHERE UserID = @UserID;

            SET @NewUserID = @UserID;
        END
        ELSE
        BEGIN
            -- The password the admin sets is the user's password; no change is forced at first login
            INSERT INTO dbo.UserMaster (Name, EmployeeID, UserName, PasswordHash, MustChangePassword, EmailAddress,
                                        MobileNo, Designation, UserImage, IsActive, CreatedBy, CreatedOn)
            VALUES (@Name, @EmployeeID, @UserName, @PasswordHash, 0, @EmailAddress,
                    @MobileNo, @Designation, @UserImage, @IsActive, @CreatedBy, GETDATE());

            SET @NewUserID = SCOPE_IDENTITY();
        END

        -- Replace roles: remove the ones not selected, add the new ones
        DELETE ur FROM dbo.UserRoles ur
        WHERE ur.UserID = @NewUserID
          AND NOT EXISTS (SELECT 1 FROM @Roles r WHERE r.RoleID = ur.RoleID);

        INSERT INTO dbo.UserRoles (UserID, RoleID, AssignedBy, AssignedOn)
        SELECT @NewUserID, r.RoleID, @CreatedBy, GETDATE()
        FROM @Roles r
        WHERE NOT EXISTS (SELECT 1 FROM dbo.UserRoles ur
                          WHERE ur.UserID = @NewUserID AND ur.RoleID = r.RoleID);

        IF @OwnTran = 1 COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @OwnTran = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
