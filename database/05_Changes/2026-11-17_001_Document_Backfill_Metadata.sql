/* =============================================================
   Change   : 2026-11-17_001
   Table    : Document (data only)
   Purpose  : Documents added before Category / Department / Plant-Area
              existed get values that fit their titles. Only fills
              fields that are still empty; values come from the
              dropdown lists. Does nothing on a database without them.
   Safe to run again.
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @fix TABLE (DocumentNumber VARCHAR(50), CategoryCode VARCHAR(10), Department VARCHAR(100), PlantArea VARCHAR(100));
INSERT INTO @fix VALUES
    ('DOC_1', 'SOP', 'Quality Control',  'QC Laboratory'),
    ('DOC_2', 'SOP', 'Quality Control',  'QC Laboratory'),
    ('DOC_3', 'SOP', 'Quality Control',  'QC Laboratory'),
    ('DOC_4', 'EMP', 'Safety (HSE)',     'Additive Plant - Reactor Section'),
    ('DOC_5', 'EMP', 'Safety (HSE)',     'Additive Plant - Reactor Section'),
    ('DOC_6', 'OCD', 'Maintenance',      'Utilities (Boiler & Cooling Tower)'),
    ('DOC_7', 'OCD', 'Maintenance',      'Maintenance Workshop'),
    ('DOC_8', 'OCD', 'Maintenance',      'Maintenance Workshop');

UPDATE d
SET CategoryID = ISNULL(d.CategoryID, c.CategoryID),
    Department = ISNULL(d.Department, f.Department),
    PlantArea  = ISNULL(d.PlantArea,  f.PlantArea),
    ModifiedOn = GETDATE()
FROM dbo.Document d
JOIN @fix f ON f.DocumentNumber = d.DocumentNumber
LEFT JOIN dbo.DocumentCategory c ON c.CategoryCode = f.CategoryCode
WHERE d.CategoryID IS NULL OR d.Department IS NULL OR d.PlantArea IS NULL;

PRINT CONCAT(@@ROWCOUNT, ' document(s) filled in.');
GO
