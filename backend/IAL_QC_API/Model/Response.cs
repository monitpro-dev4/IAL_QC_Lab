namespace IAL_QC_API.Model
{
    /// <summary>
    /// Standard response for every insert / update / action endpoint.
    /// ErrorMessage is empty on success; it holds the stored procedure's
    /// message (e.g. "Username Already Exists") on failure.
    /// </summary>
    public class APIResponse
    {
        public long ID { get; set; }
        public long SecondID { get; set; }
        public string Response { get; set; } = string.Empty;
        public string ErrorMessage { get; set; } = string.Empty;
    }
}
