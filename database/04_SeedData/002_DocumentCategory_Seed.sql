/* =============================================================
   Script   : 002_DocumentCategory_Seed.sql
   Purpose  : Starting document categories, added through
              DocumentCategoryInsertUpdate (skips existing ones).
              Edit or add categories later from the application.
   Depends  : DocumentCategoryInsertUpdate
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @ID INT;

-- The category list (and its order) is kept in 05_Changes/2026-11-11_002_Document_Department_Categories.sql,
-- which runs before this seed. This only adds a category if it is missing.
IF NOT EXISTS (SELECT 1 FROM dbo.DocumentCategory WHERE CategoryCode = 'SOP')
    EXEC dbo.DocumentCategoryInsertUpdate 0, 'SOP', 'SOPs', 'Standard operating procedures', 'Y', NULL, @ID OUTPUT;

PRINT 'DocumentCategory seed done.';
GO
