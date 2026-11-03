namespace IAL_QC_API
{
    public static class PasswordRules
    {
        /// <summary>
        /// Returns an error message, or empty when the password is acceptable.
        /// No strength rules (by decision): any non-empty password is accepted.
        /// </summary>
        public static string Validate(string password, string userName = null)
        {
            if (string.IsNullOrEmpty(password)) return "Password Is Required";
            if (password.Length > 128) return "Password Is Too Long";
            return string.Empty;
        }

        public static string Hash(string password) => BCrypt.Net.BCrypt.HashPassword(password, workFactor: 11);

        /// <summary>False for a wrong password, an empty hash or a hash that is not BCrypt.</summary>
        public static bool Verify(string password, string hash)
        {
            if (string.IsNullOrEmpty(password) || string.IsNullOrEmpty(hash)) return false;
            try { return BCrypt.Net.BCrypt.Verify(password, hash); }
            catch { return false; }
        }
    }
}
