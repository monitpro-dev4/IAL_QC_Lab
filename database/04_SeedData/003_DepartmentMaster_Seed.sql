/* =============================================================
   Script   : 003_DepartmentMaster_Seed.sql
   Purpose  : Starting departments (sample data - adjust to IAL's list).
              Adds only the ones that are missing.
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

MERGE dbo.DepartmentMaster AS t
USING (VALUES
    ('Quality Control', 1), ('Quality Assurance', 2), ('Production', 3), ('Maintenance', 4),
    ('Engineering', 5), ('Instrumentation', 6), ('Electrical', 7), ('Safety (HSE)', 8),
    ('Environment', 9), ('Logistics', 10), ('Stores', 11), ('Product Development (R&D)', 12),
    ('Administration', 13)
) AS s (DepartmentName, SortOrder)
ON t.DepartmentName = s.DepartmentName
WHEN NOT MATCHED THEN INSERT (DepartmentName, SortOrder) VALUES (s.DepartmentName, s.SortOrder);
PRINT 'DepartmentMaster seed done.';
GO
