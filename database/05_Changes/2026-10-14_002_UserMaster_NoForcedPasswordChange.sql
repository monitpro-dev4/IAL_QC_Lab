/* =============================================================
   Change   : 2026-10-14_002
   Table    : UserMaster
   Purpose  : The password the admin sets for a user is that user's
              password - users are no longer forced to change it at
              first login or after a reset. Clears the flag for users
              who were created before this change.
   Safe to run again.
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

UPDATE dbo.UserMaster SET MustChangePassword = 0 WHERE MustChangePassword = 1;
PRINT CONCAT(@@ROWCOUNT, ' user(s) no longer need to change their password.');
GO
