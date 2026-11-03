/* =============================================================
   Script   : 001_RoleMaster_Seed.sql
   Purpose  : The six roles from the technical proposal.
              Inserts through RoleMasterInsertUpdate; skips any
              role that already exists (safe to run again).
   Depends  : RoleMasterInsertUpdate
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @ID INT;

IF NOT EXISTS (SELECT 1 FROM dbo.RoleMaster WHERE RoleName = 'Administrator')
    EXEC dbo.RoleMasterInsertUpdate 0, 'Administrator',  'Manages users, roles and master data', 'Y', NULL, @ID OUTPUT;
IF NOT EXISTS (SELECT 1 FROM dbo.RoleMaster WHERE RoleName = 'Lab Manager')
    EXEC dbo.RoleMasterInsertUpdate 0, 'Lab Manager',    'Final approval (level 2) and escalations', 'Y', NULL, @ID OUTPUT;
IF NOT EXISTS (SELECT 1 FROM dbo.RoleMaster WHERE RoleName = 'Lab Supervisor')
    EXEC dbo.RoleMasterInsertUpdate 0, 'Lab Supervisor', 'First approval (level 1), maintains schedules', 'Y', NULL, @ID OUTPUT;
IF NOT EXISTS (SELECT 1 FROM dbo.RoleMaster WHERE RoleName = 'QA Manager')
    EXEC dbo.RoleMasterInsertUpdate 0, 'QA Manager',     'Reviews failed samples with the Lab Manager', 'Y', NULL, @ID OUTPUT;
IF NOT EXISTS (SELECT 1 FROM dbo.RoleMaster WHERE RoleName = 'Lab Chemist')
    EXEC dbo.RoleMasterInsertUpdate 0, 'Lab Chemist',    'Registers samples, completes tasks, uploads documents', 'Y', NULL, @ID OUTPUT;
IF NOT EXISTS (SELECT 1 FROM dbo.RoleMaster WHERE RoleName = 'Employee')
    EXEC dbo.RoleMasterInsertUpdate 0, 'Employee',       'Plant / logistics staff; raise requests and view documents', 'Y', NULL, @ID OUTPUT;

PRINT 'RoleMaster seed done.';
GO
