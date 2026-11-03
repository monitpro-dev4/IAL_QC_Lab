namespace IAL_QC_API
{
    /// <summary>A file saved on the server: what gets recorded in DocumentVersion.</summary>
    public class StoredFile
    {
        public string OriginalFileName { get; set; }
        public string StoredFileName { get; set; }
        /// <summary>Folder relative to FileSettings:DocumentRoot, e.g. "IAL-SOP-123".</summary>
        public string RelativeFolder { get; set; }
        public string FileType { get; set; }
        public int FileSizeKB { get; set; }
    }

    /// <summary>
    /// Saves uploaded document files under FileSettings:DocumentRoot,
    /// one folder per document number. Files get a new unique name on disk
    /// (the original name is kept in the database for display and download),
    /// so two uploads can never overwrite each other.
    /// </summary>
    public class FileStorage
    {
        private readonly string _root;
        private readonly long _maxBytes;
        private readonly HashSet<string> _allowed;

        public FileStorage(IConfiguration configuration)
        {
            IConfigurationSection s = configuration.GetSection("FileSettings");
            _root = Path.GetFullPath(s["DocumentRoot"] ?? throw new InvalidOperationException("FileSettings:DocumentRoot is not set"));
            _maxBytes = (s.GetValue<long?>("MaxFileSizeMB") ?? 25) * 1024 * 1024;
            _allowed = new HashSet<string>(
                s.GetSection("AllowedExtensions").Get<string[]>() ?? new[] { ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx" },
                StringComparer.OrdinalIgnoreCase);
        }

        public long MaxBytes => _maxBytes;

        /// <summary>Returns an error message, or empty when the file is acceptable.</summary>
        public string Validate(IFormFile file)
        {
            if (file == null || file.Length == 0) return "Please Select A File";
            if (file.Length > _maxBytes) return $"File Is Larger Than {_maxBytes / 1024 / 1024} MB";
            string ext = Path.GetExtension(file.FileName);
            if (string.IsNullOrEmpty(ext) || !_allowed.Contains(ext))
                return "File Type Not Allowed. Allowed: " + string.Join(", ", _allowed);
            return string.Empty;
        }

        public async Task<StoredFile> SaveAsync(IFormFile file, string documentNumber)
        {
            string folder = SafeFolderName(documentNumber);
            string dir = Path.Combine(_root, folder);
            Directory.CreateDirectory(dir);

            string ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            string storedName = Guid.NewGuid().ToString("N") + ext;
            string fullPath = Path.Combine(dir, storedName);

            await using (var stream = new FileStream(fullPath, FileMode.CreateNew))
            {
                await file.CopyToAsync(stream);
            }

            return new StoredFile
            {
                OriginalFileName = Path.GetFileName(file.FileName),
                StoredFileName = storedName,
                RelativeFolder = folder,
                FileType = ext.TrimStart('.'),
                FileSizeKB = (int)Math.Ceiling(file.Length / 1024.0)
            };
        }

        /// <summary>Removes a saved file (used when the database rejects the upload).</summary>
        public void Delete(StoredFile file)
        {
            if (file == null) return;
            string path = GetFullPath(file.RelativeFolder, file.StoredFileName);
            if (path != null && File.Exists(path)) File.Delete(path);
        }

        /// <summary>
        /// Full path of a stored file, or null if the result would fall
        /// outside the document root (protects against tampered paths).
        /// </summary>
        public string GetFullPath(string relativeFolder, string storedFileName)
        {
            if (string.IsNullOrWhiteSpace(relativeFolder) || string.IsNullOrWhiteSpace(storedFileName)) return null;
            string full = Path.GetFullPath(Path.Combine(_root, relativeFolder, storedFileName));
            string rootWithSep = _root.EndsWith(Path.DirectorySeparatorChar) ? _root : _root + Path.DirectorySeparatorChar;
            return full.StartsWith(rootWithSep, StringComparison.OrdinalIgnoreCase) ? full : null;
        }

        private static string SafeFolderName(string documentNumber)
        {
            string name = (documentNumber ?? "UNNUMBERED").Trim().ToUpperInvariant();
            foreach (char c in Path.GetInvalidFileNameChars()) name = name.Replace(c, '_');
            name = name.Replace("..", "_");
            return string.IsNullOrWhiteSpace(name) ? "UNNUMBERED" : name;
        }
    }
}
