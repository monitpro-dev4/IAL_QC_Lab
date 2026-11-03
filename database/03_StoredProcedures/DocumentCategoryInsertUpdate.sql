/* =============================================================
   Procedure : DocumentCategoryInsertUpdate
   Module    : Document Management
   Purpose   : Add a category (@CategoryID = 0) or update one
   Example   : DECLARE @ID INT;
               EXEC DocumentCategoryInsertUpdate 0, 'SOP', 'Standard Operating Procedure', NULL, 'Y', 1, @ID OUTPUT;
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DocumentCategoryInsertUpdate
    @CategoryID     INT,
    @CategoryCode   VARCHAR(10),
    @CategoryName   VARCHAR(100),
    @CategoryDesc   VARCHAR(250) = NULL,
    @IsActive       CHAR(1)      = 'Y',
    @CreatedBy      INT          = NULL,
    @NewCategoryID  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @CategoryCode = UPPER(LTRIM(RTRIM(@CategoryCode)));
        IF LTRIM(RTRIM(@CategoryDesc)) = 'null' SET @CategoryDesc = NULL;

        IF EXISTS (SELECT 1 FROM dbo.DocumentCategory
                   WHERE CategoryCode = @CategoryCode AND (@CategoryID = 0 OR CategoryID <> @CategoryID))
        BEGIN
            RAISERROR ('Category Code Already Exists', 11, 1);
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM dbo.DocumentCategory
                   WHERE CategoryName = @CategoryName AND (@CategoryID = 0 OR CategoryID <> @CategoryID))
        BEGIN
            RAISERROR ('Category Name Already Exists', 11, 1);
            RETURN;
        END

        IF @CategoryID > 0
        BEGIN
            UPDATE dbo.DocumentCategory
            SET CategoryCode = @CategoryCode,
                CategoryName = @CategoryName,
                CategoryDesc = @CategoryDesc,
                IsActive     = @IsActive,
                ModifiedBy   = @CreatedBy,
                ModifiedOn   = GETDATE()
            WHERE CategoryID = @CategoryID;

            SET @NewCategoryID = @CategoryID;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.DocumentCategory (CategoryCode, CategoryName, CategoryDesc, IsActive, CreatedBy, CreatedOn)
            VALUES (@CategoryCode, @CategoryName, @CategoryDesc, @IsActive, @CreatedBy, GETDATE());

            SET @NewCategoryID = SCOPE_IDENTITY();
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
