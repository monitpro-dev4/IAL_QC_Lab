/* =============================================================
   Change   : 2026-11-11_002
   Tables   : Document, DocumentCategory
   Purpose  : - Document.Department (entered when a document is added)
              - DocumentCategory.SortOrder, and the controlled-document
                categories in this order:
                SOPs, Work Instructions, Policies, Manuals, Standards, Forms,
                Checklists, Drawings, Emergency Procedures, HSE Plans,
                Other Controlled Documents
                (the old "ISO Document" category is switched off)
   Safe to run again.
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.Document', 'Department') IS NULL
BEGIN
    ALTER TABLE dbo.Document ADD Department VARCHAR(100) NULL;
    PRINT 'Document.Department added.';
END
GO

IF COL_LENGTH('dbo.DocumentCategory', 'SortOrder') IS NULL
BEGIN
    ALTER TABLE dbo.DocumentCategory ADD SortOrder INT NULL;
    PRINT 'DocumentCategory.SortOrder added.';
END
GO

DECLARE @c TABLE (Code VARCHAR(10), Name VARCHAR(100), Descr VARCHAR(250), Sort INT);
INSERT INTO @c VALUES
    ('SOP', 'SOPs',                       'Standard operating procedures', 1),
    ('WI',  'Work Instructions',          'Step-by-step instructions for a single task', 2),
    ('POL', 'Policies',                   'Company and department policies', 3),
    ('MAN', 'Manuals',                    'Manuals and handbooks', 4),
    ('STD', 'Standards',                  'Internal and external standards', 5),
    ('FRM', 'Forms',                      'Blank forms and record formats', 6),
    ('CHK', 'Checklists',                 'Inspection and verification checklists', 7),
    ('DRW', 'Drawings',                   'Engineering and layout drawings', 8),
    ('EMP', 'Emergency Procedures',       'Emergency response procedures', 9),
    ('HSE', 'HSE Plans',                  'Health, safety and environment plans', 10),
    ('OCD', 'Other Controlled Documents', 'Any other controlled document', 11);

-- Existing codes get the new name and order; new codes are added
UPDATE dc SET CategoryName = c.Name, CategoryDesc = c.Descr, SortOrder = c.Sort, IsActive = 'Y', ModifiedOn = GETDATE()
FROM dbo.DocumentCategory dc JOIN @c c ON c.Code = dc.CategoryCode;

INSERT INTO dbo.DocumentCategory (CategoryCode, CategoryName, CategoryDesc, SortOrder, IsActive, CreatedOn)
SELECT c.Code, c.Name, c.Descr, c.Sort, 'Y', GETDATE()
FROM @c c WHERE NOT EXISTS (SELECT 1 FROM dbo.DocumentCategory dc WHERE dc.CategoryCode = c.Code);

-- Not in the new list: kept for history, but no longer offered
UPDATE dbo.DocumentCategory SET IsActive = 'N', SortOrder = NULL, ModifiedOn = GETDATE()
WHERE CategoryCode NOT IN (SELECT Code FROM @c) AND IsActive = 'Y';

PRINT 'Document categories updated.';
GO
