using System.Configuration;
using System.Data.SqlClient;

namespace Hardwarequest.DataAccess
{
    // Central place for the connection. Every repository opens connections through here.
    public static class Db
    {
        public static SqlConnection GetConnection()
        {
            string cs = ConfigurationManager.ConnectionStrings["HardwareQuest"].ConnectionString;
            return new SqlConnection(cs);
        }

        // Brings an existing database up to date with columns added after first deploy.
        // Idempotent and safe to run on every startup: each step only acts when needed.
        public static void EnsureSchema()
        {
            using (SqlConnection con = GetConnection())
            using (var cmd = new SqlCommand(
                "IF COL_LENGTH('dbo.Quizzes','Description') IS NULL " +
                "ALTER TABLE dbo.Quizzes ADD Description NVARCHAR(500) NULL; " +
                "IF COL_LENGTH('dbo.Quizzes','ImagePath') IS NULL " +
                "ALTER TABLE dbo.Quizzes ADD ImagePath NVARCHAR(256) NULL; " +
                "IF COL_LENGTH('dbo.Quizzes','CreatedByUserId') IS NULL " +
                "ALTER TABLE dbo.Quizzes ADD CreatedByUserId INT NULL; " +
                "IF COL_LENGTH('dbo.Quizzes','IsPublished') IS NULL " +
                "ALTER TABLE dbo.Quizzes ADD IsPublished BIT NOT NULL DEFAULT 1; " +
                "IF OBJECT_ID('dbo.Topics','U') IS NULL " +
                "CREATE TABLE dbo.Topics (" +
                "TopicId INT IDENTITY(1,1) PRIMARY KEY, " +
                "Title NVARCHAR(150) NOT NULL, " +
                "Body NVARCHAR(MAX) NOT NULL, " +
                "ImagePath NVARCHAR(256) NULL, " +
                "CreatedByUserId INT NULL, " +
                "CreatedAt DATETIME NOT NULL DEFAULT GETDATE());", con))
            {
                con.Open();
                cmd.ExecuteNonQuery();
            }
        }
    }
}
