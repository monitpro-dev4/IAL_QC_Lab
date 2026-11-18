using Microsoft.Data.SqlClient;
using System.Data;

namespace IAL_QC_API.DAL
{
    /// <summary>
    /// Small helpers so every DAL reads columns the same way:
    /// DBNull becomes null / empty instead of throwing.
    /// </summary>
    public static class DBHelper
    {
        public static SqlCommand StoredProcedure(string name, SqlConnection conn)
        {
            return new SqlCommand(name, conn) { CommandType = CommandType.StoredProcedure };
        }

        /// <summary>Adds a parameter, sending DBNull for null values.</summary>
        public static SqlParameter Add(this SqlCommand cmd, string name, object value)
        {
            return cmd.Parameters.AddWithValue(name, value ?? DBNull.Value);
        }

        public static SqlParameter AddOutputInt(this SqlCommand cmd, string name)
        {
            var p = new SqlParameter(name, SqlDbType.Int) { Direction = ParameterDirection.Output };
            cmd.Parameters.Add(p);
            return p;
        }

        public static string Str(this SqlDataReader r, string col)
        {
            object v = r[col];
            return v == DBNull.Value ? string.Empty : Convert.ToString(v);
        }

        public static int Int(this SqlDataReader r, string col)
        {
            object v = r[col];
            return v == DBNull.Value ? 0 : Convert.ToInt32(v);
        }

        public static int? NInt(this SqlDataReader r, string col)
        {
            object v = r[col];
            return v == DBNull.Value ? (int?)null : Convert.ToInt32(v);
        }

        public static long Long(this SqlDataReader r, string col)
        {
            object v = r[col];
            return v == DBNull.Value ? 0 : Convert.ToInt64(v);
        }

        public static decimal? NDec(this SqlDataReader r, string col)
        {
            object v = r[col];
            return v == DBNull.Value ? (decimal?)null : Convert.ToDecimal(v);
        }

        public static DateTime? NDate(this SqlDataReader r, string col)
        {
            object v = r[col];
            return v == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(v);
        }
    }
}
