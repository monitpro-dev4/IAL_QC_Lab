namespace IAL_QC_API.Model
{
    public class LoginRequest
    {
        public string UserName { get; set; }
        public string Password { get; set; }
    }

    public class LoginResponse
    {
        public string Token { get; set; } = string.Empty;
        public int UserID { get; set; }
        public string Name { get; set; }
        public string UserName { get; set; }
        public List<string> Roles { get; set; } = new List<string>();
        public bool MustChangePassword { get; set; }
        public string ErrorMessage { get; set; } = string.Empty;
    }

    public class ChangePasswordRequest
    {
        public string CurrentPassword { get; set; }
        public string NewPassword { get; set; }
    }

    /// <summary>Creates the first Administrator; only allowed while there are no users at all.</summary>
    public class SetupRequest
    {
        public string Name { get; set; }
        public string EmployeeID { get; set; }
        public string UserName { get; set; }
        public string Password { get; set; }
    }

    public class SetupStatus
    {
        public bool NeedsSetup { get; set; }
    }

    public class UserPasswordResetModel
    {
        public int UserID { get; set; }
        public string NewPassword { get; set; }
    }

    /// <summary>A user as read for login (includes the password hash; never sent to the browser).</summary>
    public class LoginUser
    {
        public int UserID { get; set; }
        public string Name { get; set; }
        public string UserName { get; set; }
        public string PasswordHash { get; set; }
        public bool MustChangePassword { get; set; }
        public bool IsLocked { get; set; }
        public DateTime? LockedUntil { get; set; }
        public List<string> Roles { get; set; } = new List<string>();
    }

    /// <summary>The user behind a valid login token.</summary>
    public class SessionUser
    {
        public int UserID { get; set; }
        public string Name { get; set; }
        public string UserName { get; set; }
        public bool MustChangePassword { get; set; }
        public List<string> Roles { get; set; } = new List<string>();
    }
}
