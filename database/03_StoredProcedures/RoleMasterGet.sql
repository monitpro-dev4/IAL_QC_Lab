/* =============================================================
   Procedure : RoleMasterGet
   Purpose   : Role list (role dropdown, role master page)
   Params    : @IsActive  NULL = all, 'Y' = active only
   Example   : EXEC RoleMasterGet 'Y';
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.RoleMasterGet
    @IsActive CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT RoleID, RoleName, RoleDesc, IsActive, CreatedOn, ModifiedOn
        FROM dbo.RoleMaster
        WHERE (@IsActive IS NULL OR IsActive = @IsActive)
        ORDER BY RoleName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
