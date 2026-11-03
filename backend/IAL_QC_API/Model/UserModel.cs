namespace IAL_QC_API.Model
{
    /// <summary>Input for UserInsertUpdate. UserID = 0 adds a new user.</summary>
    public class UserModel
    {
        public int UserID { get; set; }
        public string Name { get; set; }
        public string EmployeeID { get; set; }
        public string UserName { get; set; }
        public string EmailAddress { get; set; }
        public string MobileNo { get; set; }
        public string Designation { get; set; }
        public string UserImage { get; set; }
        public string IsActive { get; set; } = "Y";
        /// <summary>Comma-separated role IDs, e.g. "3,5".</summary>
        public string RoleIDs { get; set; }
        /// <summary>First password, required for a new user (they must change it at first login). Ignored on update.</summary>
        public string Password { get; set; }
        /// <summary>Ignored: the signed-in user is taken from the login token.</summary>
        public int CreatedBy { get; set; }
    }

    /// <summary>One row of the user list.</summary>
    public class UserListModel
    {
        public int UserID { get; set; }
        public string Name { get; set; }
        public string EmployeeID { get; set; }
        public string UserName { get; set; }
        public string EmailAddress { get; set; }
        public string MobileNo { get; set; }
        public string Designation { get; set; }
        public string UserImage { get; set; }
        public string IsActive { get; set; }
        public DateTime? CreatedOn { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public string RoleIDs { get; set; }
        public string RoleNames { get; set; }
    }

    /// <summary>One user with their roles, for the edit form.</summary>
    public class UserDetailModel
    {
        public int UserID { get; set; }
        public string Name { get; set; }
        public string EmployeeID { get; set; }
        public string UserName { get; set; }
        public string EmailAddress { get; set; }
        public string MobileNo { get; set; }
        public string Designation { get; set; }
        public string UserImage { get; set; }
        public string IsActive { get; set; }
        public int? CreatedBy { get; set; }
        public DateTime? CreatedOn { get; set; }
        public int? ModifiedBy { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public List<RoleModel> Roles { get; set; } = new List<RoleModel>();
        public string ErrorMessage { get; set; } = string.Empty;
    }

    public class UserStatusModel
    {
        public int UserID { get; set; }
        public string IsActive { get; set; }
        public int ModifiedBy { get; set; }
    }
}
