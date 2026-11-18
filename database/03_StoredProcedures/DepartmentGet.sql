/* =============================================================
   Procedure : DepartmentGet
   Purpose   : Department dropdown list
   Params    : @IsActive  NULL = all, 'Y' = active only
   Example   : EXEC DepartmentGet 'Y';
   Added     : 2026-11-13
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DepartmentGet
    @IsActive CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT DepartmentID, DepartmentName, IsActive
        FROM dbo.DepartmentMaster
        WHERE (@IsActive IS NULL OR IsActive = @IsActive)
        ORDER BY ISNULL(SortOrder, 999), DepartmentName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
