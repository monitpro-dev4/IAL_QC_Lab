/* =============================================================
   Procedure : RoleMasterInsertUpdate
   Purpose   : Add a role (@RoleID = 0) or update an existing one
   Example   : DECLARE @ID INT;
               EXEC RoleMasterInsertUpdate 0, 'Lab Chemist', 'Lab chemist', 'Y', 1, @ID OUTPUT;
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.RoleMasterInsertUpdate
    @RoleID     INT,
    @RoleName   VARCHAR(50),
    @RoleDesc   VARCHAR(250) = NULL,
    @IsActive   CHAR(1)      = 'Y',
    @CreatedBy  INT          = NULL,
    @NewRoleID  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

        IF EXISTS (SELECT 1 FROM dbo.RoleMaster
                   WHERE RoleName = @RoleName AND (@RoleID = 0 OR RoleID <> @RoleID))
        BEGIN
            RAISERROR ('Role Name Already Exists', 11, 1);
            RETURN;
        END

        IF @RoleID > 0
        BEGIN
            UPDATE dbo.RoleMaster
            SET RoleName   = @RoleName,
                RoleDesc   = @RoleDesc,
                IsActive   = @IsActive,
                ModifiedBy = @CreatedBy,
                ModifiedOn = GETDATE()
            WHERE RoleID = @RoleID;

            SET @NewRoleID = @RoleID;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.RoleMaster (RoleName, RoleDesc, IsActive, CreatedBy, CreatedOn)
            VALUES (@RoleName, @RoleDesc, @IsActive, @CreatedBy, GETDATE());

            SET @NewRoleID = SCOPE_IDENTITY();
        END

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
