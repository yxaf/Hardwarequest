using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using Hardwarequest.Models;

namespace Hardwarequest.DataAccess
{
    // All SQL for the discussion forum: threads and their posts.
    public class ForumRepository
    {
        // ---------- Threads ----------

        // Every thread with its author, reply count, and most-recent activity time.
        public List<ForumThread> GetAllThreads()
        {
            var list = new List<ForumThread>();
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT t.ThreadId, t.Title, t.CreatedByUserId, t.CreatedAt, u.FullName, " +
                "  (SELECT COUNT(1) FROM ForumPosts WHERE ThreadId = t.ThreadId) AS PostCount, " +
                "  (SELECT MAX(CreatedAt) FROM ForumPosts WHERE ThreadId = t.ThreadId) AS LastAt " +
                "FROM ForumThreads t " +
                "JOIN Users u ON u.UserId = t.CreatedByUserId " +
                "ORDER BY LastAt DESC", con))
            {
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read())
                    {
                        int postCount = (int)r["PostCount"];
                        list.Add(new ForumThread
                        {
                            ThreadId = (int)r["ThreadId"],
                            Title = (string)r["Title"],
                            CreatedByUserId = (int)r["CreatedByUserId"],
                            CreatedAt = (DateTime)r["CreatedAt"],
                            AuthorName = (string)r["FullName"],
                            // The opening post is not a "reply", so subtract it.
                            ReplyCount = postCount > 0 ? postCount - 1 : 0,
                            LastActivity = r["LastAt"] is DateTime d ? d : (DateTime)r["CreatedAt"]
                        });
                    }
            }
            return list;
        }

        // Threads for the Manage hub: admin sees all, a lecturer only their own.
        // Reuses the same projection as GetAllThreads, then filters by author.
        public List<ForumThread> GetThreadsForManager(int? userId, bool isAdmin)
        {
            if (isAdmin) return GetAllThreads();
            var mine = new List<ForumThread>();
            foreach (var t in GetAllThreads())
                if (t.CreatedByUserId == userId) mine.Add(t);
            return mine;
        }

        public ForumThread GetThreadById(int threadId)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT t.ThreadId, t.Title, t.CreatedByUserId, t.CreatedAt, u.FullName " +
                "FROM ForumThreads t JOIN Users u ON u.UserId = t.CreatedByUserId " +
                "WHERE t.ThreadId = @id", con))
            {
                cmd.Parameters.AddWithValue("@id", threadId);
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    return r.Read()
                        ? new ForumThread
                        {
                            ThreadId = (int)r["ThreadId"],
                            Title = (string)r["Title"],
                            CreatedByUserId = (int)r["CreatedByUserId"],
                            CreatedAt = (DateTime)r["CreatedAt"],
                            AuthorName = (string)r["FullName"]
                        }
                        : null;
            }
        }

        // Creates a thread and its opening post together (all-or-nothing).
        public int CreateThread(int userId, string title, string body)
        {
            using (SqlConnection con = Db.GetConnection())
            {
                con.Open();
                using (SqlTransaction tx = con.BeginTransaction())
                {
                    int threadId;
                    using (var cmd = new SqlCommand(
                        "INSERT INTO ForumThreads (Title, CreatedByUserId) VALUES (@t, @u); " +
                        "SELECT CAST(SCOPE_IDENTITY() AS INT);", con, tx))
                    {
                        cmd.Parameters.AddWithValue("@t", title);
                        cmd.Parameters.AddWithValue("@u", userId);
                        threadId = (int)cmd.ExecuteScalar();
                    }
                    using (var cmd = new SqlCommand(
                        "INSERT INTO ForumPosts (ThreadId, UserId, Body) VALUES (@th, @u, @b);", con, tx))
                    {
                        cmd.Parameters.AddWithValue("@th", threadId);
                        cmd.Parameters.AddWithValue("@u", userId);
                        cmd.Parameters.AddWithValue("@b", body);
                        cmd.ExecuteNonQuery();
                    }
                    tx.Commit();
                    return threadId;
                }
            }
        }

        // ---------- Posts ----------

        public List<ForumPost> GetPosts(int threadId)
        {
            var list = new List<ForumPost>();
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT p.PostId, p.ThreadId, p.UserId, p.Body, p.CreatedAt, u.FullName " +
                "FROM ForumPosts p JOIN Users u ON u.UserId = p.UserId " +
                "WHERE p.ThreadId = @id ORDER BY p.CreatedAt ASC", con))
            {
                cmd.Parameters.AddWithValue("@id", threadId);
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read())
                        list.Add(new ForumPost
                        {
                            PostId = (int)r["PostId"],
                            ThreadId = (int)r["ThreadId"],
                            UserId = (int)r["UserId"],
                            Body = (string)r["Body"],
                            CreatedAt = (DateTime)r["CreatedAt"],
                            AuthorName = (string)r["FullName"]
                        });
            }
            return list;
        }

        public void AddPost(int threadId, int userId, string body)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "INSERT INTO ForumPosts (ThreadId, UserId, Body) VALUES (@th, @u, @b);", con))
            {
                cmd.Parameters.AddWithValue("@th", threadId);
                cmd.Parameters.AddWithValue("@u", userId);
                cmd.Parameters.AddWithValue("@b", body);
                con.Open();
                cmd.ExecuteNonQuery();
            }
        }

        // Staff moderation: remove a single post.
        public void DeletePost(int postId)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand("DELETE FROM ForumPosts WHERE PostId=@id", con))
            {
                cmd.Parameters.AddWithValue("@id", postId);
                con.Open();
                cmd.ExecuteNonQuery();
            }
        }

        // Returns how many posts a thread has (used to tidy up empty threads).
        public int CountPosts(int threadId)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand("SELECT COUNT(1) FROM ForumPosts WHERE ThreadId=@id", con))
            {
                cmd.Parameters.AddWithValue("@id", threadId);
                con.Open();
                return (int)cmd.ExecuteScalar();
            }
        }

        // Staff moderation: remove a whole thread and its posts.
        public void DeleteThread(int threadId)
        {
            using (SqlConnection con = Db.GetConnection())
            {
                con.Open();
                using (SqlTransaction tx = con.BeginTransaction())
                {
                    foreach (string sql in new[]
                    {
                        "DELETE FROM ForumPosts WHERE ThreadId=@id",
                        "DELETE FROM ForumThreads WHERE ThreadId=@id"
                    })
                        using (var cmd = new SqlCommand(sql, con, tx))
                        {
                            cmd.Parameters.AddWithValue("@id", threadId);
                            cmd.ExecuteNonQuery();
                        }
                    tx.Commit();
                }
            }
        }
    }
}
