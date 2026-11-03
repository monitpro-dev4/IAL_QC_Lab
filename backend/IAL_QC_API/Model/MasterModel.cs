namespace IAL_QC_API.Model
{
    //=========================== Roles ===========================

    public class RoleModel
    {
        public int RoleID { get; set; }
        public string RoleName { get; set; }
        public string RoleDesc { get; set; }
        public string IsActive { get; set; } = "Y";
        public int? CreatedBy { get; set; }
        public DateTime? CreatedOn { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }

    //=========================== Document categories ===========================

    public class DocumentCategoryModel
    {
        public int CategoryID { get; set; }
        public string CategoryCode { get; set; }
        public string CategoryName { get; set; }
        public string CategoryDesc { get; set; }
        public string IsActive { get; set; } = "Y";
        public int? CreatedBy { get; set; }
        public DateTime? CreatedOn { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }
}
