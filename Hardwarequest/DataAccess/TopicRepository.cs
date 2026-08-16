using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using Hardwarequest.Models;

namespace Hardwarequest.DataAccess
{
    // All SQL for the Topics (learning material) module.
    public class TopicRepository
    {
        public List<Topic> GetAll()
        {
            var list = new List<Topic>();
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT TopicId, Title, Body, ImagePath, CreatedByUserId, CreatedAt " +
                "FROM Topics ORDER BY CreatedAt DESC", con))
            {
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read()) list.Add(Map(r));
            }
            return list;
        }

        // Topics for the Manage hub: admin sees all, a lecturer only their own.
        public List<Topic> GetTopicsForManager(int? userId, bool isAdmin)
        {
            var list = new List<Topic>();
            string sql =
                "SELECT t.TopicId, t.Title, t.Body, t.ImagePath, t.CreatedByUserId, t.CreatedAt, " +
                "       u.Username AS OwnerName " +
                "FROM Topics t LEFT JOIN Users u ON u.UserId = t.CreatedByUserId";
            if (!isAdmin) sql += " WHERE t.CreatedByUserId = @uid";
            sql += " ORDER BY t.CreatedAt DESC";

            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(sql, con))
            {
                if (!isAdmin) cmd.Parameters.AddWithValue("@uid", (object)userId ?? DBNull.Value);
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read())
                        list.Add(new Topic
                        {
                            TopicId = (int)r["TopicId"],
                            Title = (string)r["Title"],
                            Body = (string)r["Body"],
                            ImagePath = r["ImagePath"] as string,
                            CreatedByUserId = r["CreatedByUserId"] as int?,
                            CreatedAt = (DateTime)r["CreatedAt"],
                            OwnerName = r["OwnerName"] as string
                        });
            }
            return list;
        }

        public Topic GetById(int id)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT TopicId, Title, Body, ImagePath, CreatedByUserId, CreatedAt " +
                "FROM Topics WHERE TopicId=@id", con))
            {
                cmd.Parameters.AddWithValue("@id", id);
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    return r.Read() ? Map(r) : null;
            }
        }

        public int Create(Topic t)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "INSERT INTO Topics (Title, Body, ImagePath, CreatedByUserId) " +
                "VALUES (@t, @b, @img, @by); SELECT CAST(SCOPE_IDENTITY() AS INT);", con))
            {
                cmd.Parameters.AddWithValue("@t", t.Title);
                cmd.Parameters.AddWithValue("@b", t.Body);
                cmd.Parameters.AddWithValue("@img", NullParam(t.ImagePath));
                cmd.Parameters.AddWithValue("@by", (object)t.CreatedByUserId ?? DBNull.Value);
                con.Open();
                return (int)cmd.ExecuteScalar();
            }
        }

        // Updates editable fields; ownership is unchanged.
        public void Update(Topic t)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "UPDATE Topics SET Title=@t, Body=@b, ImagePath=@img WHERE TopicId=@id", con))
            {
                cmd.Parameters.AddWithValue("@t", t.Title);
                cmd.Parameters.AddWithValue("@b", t.Body);
                cmd.Parameters.AddWithValue("@img", NullParam(t.ImagePath));
                cmd.Parameters.AddWithValue("@id", t.TopicId);
                con.Open();
                cmd.ExecuteNonQuery();
            }
        }

        public void Delete(int id)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand("DELETE FROM Topics WHERE TopicId=@id", con))
            {
                cmd.Parameters.AddWithValue("@id", id);
                con.Open();
                cmd.ExecuteNonQuery();
            }
        }

        private static object NullParam(string value) =>
            string.IsNullOrWhiteSpace(value) ? (object)DBNull.Value : value;

        private static Topic Map(IDataRecord r) => new Topic
        {
            TopicId = (int)r["TopicId"],
            Title = (string)r["Title"],
            Body = (string)r["Body"],
            ImagePath = r["ImagePath"] as string,
            CreatedByUserId = r["CreatedByUserId"] as int?,
            CreatedAt = (DateTime)r["CreatedAt"]
        };
    }
}
