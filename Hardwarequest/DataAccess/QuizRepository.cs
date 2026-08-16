using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using Hardwarequest.Models;

namespace Hardwarequest.DataAccess
{
    // All SQL for the Quiz module: quizzes, their questions, and score entries.
    public class QuizRepository
    {
        // ---------- Quizzes ----------

        // All quizzes, optionally filtered by difficulty and/or published state.
        // Student-facing pages pass publishedOnly: true so drafts stay hidden.
        public List<Models.Quiz> GetAllQuizzes(string difficulty = null, bool publishedOnly = false)
        {
            var list = new List<Models.Quiz>();
            string sql =
                "SELECT q.QuizId, q.Title, q.Difficulty, q.Description, q.ImagePath, q.CreatedByUserId, q.IsPublished, " +
                "       (SELECT COUNT(1) FROM Questions WHERE QuizId = q.QuizId) AS QCount " +
                "FROM Quizzes q WHERE 1=1";
            if (!string.IsNullOrEmpty(difficulty))
                sql += " AND q.Difficulty = @diff";
            if (publishedOnly)
                sql += " AND q.IsPublished = 1";
            sql += " ORDER BY q.Title";

            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(sql, con))
            {
                if (!string.IsNullOrEmpty(difficulty))
                    cmd.Parameters.AddWithValue("@diff", difficulty);
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read())
                        list.Add(new Models.Quiz
                        {
                            QuizId = (int)r["QuizId"],
                            Title = (string)r["Title"],
                            Difficulty = (string)r["Difficulty"],
                            Description = r["Description"] as string,
                            ImagePath = r["ImagePath"] as string,
                            CreatedByUserId = r["CreatedByUserId"] as int?,
                            IsPublished = (bool)r["IsPublished"],
                            QuestionCount = (int)r["QCount"]
                        });
            }
            return list;
        }

        // Quizzes for the Manage hub: admin sees all, a lecturer only their own.
        // Each row carries usage aggregates and the creator's username.
        public List<QuizManageRow> GetQuizzesForManager(int? userId, bool isAdmin)
        {
            var list = new List<QuizManageRow>();
            string sql =
                "SELECT q.QuizId, q.Title, q.Difficulty, q.CreatedByUserId, q.IsPublished, u.Username AS OwnerName, " +
                "  (SELECT COUNT(1) FROM Questions WHERE QuizId = q.QuizId) AS QCount, " +
                "  (SELECT COUNT(1) FROM Scores WHERE QuizId = q.QuizId) AS Attempts, " +
                "  (SELECT COUNT(DISTINCT UserId) FROM Scores WHERE QuizId = q.QuizId) AS Students, " +
                "  (SELECT AVG(CAST(Points AS FLOAT)) FROM Scores WHERE QuizId = q.QuizId) AS AvgPoints " +
                "FROM Quizzes q LEFT JOIN Users u ON u.UserId = q.CreatedByUserId";
            if (!isAdmin) sql += " WHERE q.CreatedByUserId = @uid";
            sql += " ORDER BY q.Title";

            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(sql, con))
            {
                if (!isAdmin) cmd.Parameters.AddWithValue("@uid", (object)userId ?? DBNull.Value);
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read())
                    {
                        int qCount = (int)r["QCount"];
                        string diff = (string)r["Difficulty"];
                        int maxPoints = qCount * QuizDifficulty.Weight(diff);
                        double avgPoints = r["AvgPoints"] == DBNull.Value ? 0 : Convert.ToDouble(r["AvgPoints"]);
                        list.Add(new QuizManageRow
                        {
                            QuizId = (int)r["QuizId"],
                            Title = (string)r["Title"],
                            Difficulty = diff,
                            QuestionCount = qCount,
                            CreatedByUserId = r["CreatedByUserId"] as int?,
                            OwnerName = r["OwnerName"] as string,
                            IsPublished = (bool)r["IsPublished"],
                            AttemptCount = (int)r["Attempts"],
                            StudentCount = (int)r["Students"],
                            AvgAccuracy = maxPoints > 0 ? avgPoints / maxPoints : 0
                        });
                    }
            }
            return list;
        }

        // Full statistics for one quiz, derived entirely from the Scores table.
        public QuizStats GetQuizStats(int quizId)
        {
            Models.Quiz quiz = GetQuizById(quizId);
            if (quiz == null) return null;

            int qCount;
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT COUNT(1) FROM Questions WHERE QuizId=@id", con))
            {
                cmd.Parameters.AddWithValue("@id", quizId);
                con.Open();
                qCount = (int)cmd.ExecuteScalar();
            }

            var stats = new QuizStats
            {
                QuizId = quiz.QuizId,
                Title = quiz.Title,
                Difficulty = quiz.Difficulty,
                CreatedByUserId = quiz.CreatedByUserId,
                QuestionCount = qCount,
                Weight = QuizDifficulty.Weight(quiz.Difficulty),
                MaxPoints = qCount * QuizDifficulty.Weight(quiz.Difficulty)
            };

            // Per-student roster: best attempt + activity.
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT u.FullName, COUNT(1) AS Attempts, MAX(s.Points) AS BestPoints, " +
                "       MAX(s.TakenAt) AS LastTaken " +
                "FROM Scores s JOIN Users u ON u.UserId = s.UserId " +
                "WHERE s.QuizId=@id AND u.Role='Student' " +
                "GROUP BY u.FullName ORDER BY MAX(s.Points) DESC, u.FullName", con))
            {
                cmd.Parameters.AddWithValue("@id", quizId);
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read())
                    {
                        int best = (int)r["BestPoints"];
                        double acc = stats.MaxPoints > 0 ? (double)best / stats.MaxPoints : 0;
                        stats.Roster.Add(new StudentStatRow
                        {
                            FullName = r["FullName"] as string ?? "(unknown)",
                            Attempts = (int)r["Attempts"],
                            BestPoints = best,
                            BestAccuracy = acc,
                            LastTaken = (DateTime)r["LastTaken"]
                        });
                    }
            }

            // Attempts-over-time timeline.
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT CAST(s.TakenAt AS DATE) AS Day, COUNT(1) AS C " +
                "FROM Scores s JOIN Users u ON u.UserId = s.UserId " +
                "WHERE s.QuizId=@id AND u.Role='Student' " +
                "GROUP BY CAST(s.TakenAt AS DATE) ORDER BY Day", con))
            {
                cmd.Parameters.AddWithValue("@id", quizId);
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read())
                        stats.Timeline.Add(new TimelinePoint
                        {
                            Day = (DateTime)r["Day"],
                            Count = (int)r["C"]
                        });
            }

            // Aggregates + distribution from the roster (best attempt per student).
            stats.StudentCount = stats.Roster.Count;
            stats.AttemptCount = 0;
            foreach (var s in stats.Roster) stats.AttemptCount += s.Attempts;
            if (stats.Roster.Count > 0)
            {
                int bestOfAll = 0; double accSum = 0; DateTime last = DateTime.MinValue;
                foreach (var s in stats.Roster)
                {
                    if (s.BestPoints > bestOfAll) bestOfAll = s.BestPoints;
                    accSum += s.BestAccuracy;
                    if (s.LastTaken > last) last = s.LastTaken;
                    int bucket = (int)Math.Round(s.BestAccuracy * 4); // 0..4 -> 0/25/50/75/100
                    if (bucket < 0) bucket = 0;
                    if (bucket > 4) bucket = 4;
                    stats.Distribution[bucket]++;
                }
                stats.BestPoints = bestOfAll;
                stats.AvgAccuracy = accSum / stats.Roster.Count;
                stats.LastTaken = last;
            }
            return stats;
        }

        public Models.Quiz GetQuizById(int quizId)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT QuizId, Title, Difficulty, Description, ImagePath, CreatedByUserId, IsPublished FROM Quizzes WHERE QuizId=@id", con))
            {
                cmd.Parameters.AddWithValue("@id", quizId);
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    return r.Read()
                        ? new Models.Quiz
                        {
                            QuizId = (int)r["QuizId"],
                            Title = (string)r["Title"],
                            Difficulty = (string)r["Difficulty"],
                            Description = r["Description"] as string,
                            ImagePath = r["ImagePath"] as string,
                            CreatedByUserId = r["CreatedByUserId"] as int?,
                            IsPublished = (bool)r["IsPublished"]
                        }
                        : null;
            }
        }

        public int CreateQuiz(Models.Quiz q)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "INSERT INTO Quizzes (Title, Difficulty, Description, ImagePath, CreatedByUserId, IsPublished) " +
                "VALUES (@t, @d, @desc, @img, @by, @pub); " +
                "SELECT CAST(SCOPE_IDENTITY() AS INT);", con))
            {
                AddQuizParams(cmd, q);
                cmd.Parameters.AddWithValue("@by", (object)q.CreatedByUserId ?? DBNull.Value);
                con.Open();
                return (int)cmd.ExecuteScalar();
            }
        }

        // Shared column parameters for quiz INSERT/UPDATE.
        private static void AddQuizParams(SqlCommand cmd, Models.Quiz q)
        {
            cmd.Parameters.AddWithValue("@t", q.Title);
            cmd.Parameters.AddWithValue("@d", q.Difficulty);
            cmd.Parameters.AddWithValue("@desc", DescParam(q.Description));
            cmd.Parameters.AddWithValue("@img", NullParam(q.ImagePath));
            cmd.Parameters.AddWithValue("@pub", q.IsPublished);
        }

        // Saves the quiz row and its FULL question list in one transaction.
        // QuizId == 0 inserts a new quiz; otherwise updates (owner unchanged).
        // Questions are replaced wholesale: delete + reinsert in display order.
        // Safe because nothing references QuestionId (Scores keys on QuizId only),
        // and identity order preserves the author's ordering for GetQuestions.
        public int SaveQuizWithQuestions(Models.Quiz quiz, List<Question> questions)
        {
            using (SqlConnection con = Db.GetConnection())
            {
                con.Open();
                using (SqlTransaction tx = con.BeginTransaction())
                {
                    if (quiz.QuizId == 0)
                    {
                        using (var cmd = new SqlCommand(
                            "INSERT INTO Quizzes (Title, Difficulty, Description, ImagePath, CreatedByUserId, IsPublished) " +
                            "VALUES (@t, @d, @desc, @img, @by, @pub); SELECT CAST(SCOPE_IDENTITY() AS INT);", con, tx))
                        {
                            AddQuizParams(cmd, quiz);
                            cmd.Parameters.AddWithValue("@by", (object)quiz.CreatedByUserId ?? DBNull.Value);
                            quiz.QuizId = (int)cmd.ExecuteScalar();
                        }
                    }
                    else
                    {
                        using (var cmd = new SqlCommand(
                            "UPDATE Quizzes SET Title=@t, Difficulty=@d, Description=@desc, ImagePath=@img, IsPublished=@pub " +
                            "WHERE QuizId=@id", con, tx))
                        {
                            AddQuizParams(cmd, quiz);
                            cmd.Parameters.AddWithValue("@id", quiz.QuizId);
                            cmd.ExecuteNonQuery();
                        }
                    }

                    using (var cmd = new SqlCommand("DELETE FROM Questions WHERE QuizId=@id", con, tx))
                    {
                        cmd.Parameters.AddWithValue("@id", quiz.QuizId);
                        cmd.ExecuteNonQuery();
                    }
                    foreach (Question q in questions)
                    {
                        q.QuizId = quiz.QuizId;
                        using (var cmd = new SqlCommand(
                            "INSERT INTO Questions (QuizId, Text, OptionA, OptionB, OptionC, OptionD, CorrectOption) " +
                            "VALUES (@qz, @t, @a, @b, @c, @d, @correct)", con, tx))
                        {
                            AddQuestionParams(cmd, q);
                            cmd.ExecuteNonQuery();
                        }
                    }
                    tx.Commit();
                }
            }
            return quiz.QuizId;
        }

        // Stores a blank description as SQL NULL rather than an empty string.
        private static object DescParam(string description) =>
            string.IsNullOrWhiteSpace(description) ? (object)DBNull.Value : description.Trim();

        // Stores a blank/absent value (e.g. no image) as SQL NULL.
        private static object NullParam(string value) =>
            string.IsNullOrWhiteSpace(value) ? (object)DBNull.Value : value;

        // Removes a quiz together with its questions and score history.
        public void DeleteQuiz(int quizId)
        {
            using (SqlConnection con = Db.GetConnection())
            {
                con.Open();
                using (SqlTransaction tx = con.BeginTransaction())
                {
                    DeleteWhere(con, tx, "DELETE FROM Scores WHERE QuizId=@id", quizId);
                    DeleteWhere(con, tx, "DELETE FROM Questions WHERE QuizId=@id", quizId);
                    DeleteWhere(con, tx, "DELETE FROM Quizzes WHERE QuizId=@id", quizId);
                    tx.Commit();
                }
            }
        }

        private static void DeleteWhere(SqlConnection con, SqlTransaction tx, string sql, int id)
        {
            using (var cmd = new SqlCommand(sql, con, tx))
            {
                cmd.Parameters.AddWithValue("@id", id);
                cmd.ExecuteNonQuery();
            }
        }

        // ---------- Questions ----------

        public List<Question> GetQuestions(int quizId)
        {
            var list = new List<Question>();
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT QuestionId, QuizId, Text, OptionA, OptionB, OptionC, OptionD, CorrectOption " +
                "FROM Questions WHERE QuizId=@id ORDER BY QuestionId", con))
            {
                cmd.Parameters.AddWithValue("@id", quizId);
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read()) list.Add(MapQuestion(r));
            }
            return list;
        }

        public int CreateQuestion(Question q)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "INSERT INTO Questions (QuizId, Text, OptionA, OptionB, OptionC, OptionD, CorrectOption) " +
                "VALUES (@qz, @t, @a, @b, @c, @d, @correct); " +
                "SELECT CAST(SCOPE_IDENTITY() AS INT);", con))
            {
                AddQuestionParams(cmd, q);
                con.Open();
                return (int)cmd.ExecuteScalar();
            }
        }

        private static void AddQuestionParams(SqlCommand cmd, Question q)
        {
            cmd.Parameters.AddWithValue("@qz", q.QuizId);
            cmd.Parameters.AddWithValue("@t", q.Text);
            cmd.Parameters.AddWithValue("@a", (object)q.OptionA ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@b", (object)q.OptionB ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@c", (object)q.OptionC ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@d", (object)q.OptionD ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@correct", q.CorrectOption.ToString());
        }

        private static Question MapQuestion(IDataRecord r) => new Question
        {
            QuestionId = (int)r["QuestionId"],
            QuizId = (int)r["QuizId"],
            Text = (string)r["Text"],
            OptionA = r["OptionA"] as string,
            OptionB = r["OptionB"] as string,
            OptionC = r["OptionC"] as string,
            OptionD = r["OptionD"] as string,
            CorrectOption = ((string)r["CorrectOption"])[0]
        };

        // ---------- Scores ----------

        public int AddScore(Score s)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "INSERT INTO Scores (UserId, QuizId, Points) VALUES (@u, @q, @p); " +
                "SELECT CAST(SCOPE_IDENTITY() AS INT);", con))
            {
                cmd.Parameters.AddWithValue("@u", s.UserId);
                cmd.Parameters.AddWithValue("@q", s.QuizId);
                cmd.Parameters.AddWithValue("@p", s.Points);
                con.Open();
                return (int)cmd.ExecuteScalar();
            }
        }

        // Leaderboard: each user's BEST score per quiz (so repeat attempts don't
        // flood the board), highest points first, earliest achiever wins ties.
        // Top scores for a SINGLE quiz: each student's best attempt, ranked.
        public List<Score> GetLeaderboard(int quizId, int top = 20)
        {
            var list = new List<Score>();
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT TOP (@top) MIN(s.ScoreId) AS ScoreId, s.UserId, s.QuizId, " +
                "       MAX(s.Points) AS Points, MIN(s.TakenAt) AS TakenAt, " +
                "       u.FullName, q.Title AS QuizTitle " +
                "FROM Scores s " +
                "JOIN Users u   ON u.UserId = s.UserId " +
                "JOIN Quizzes q ON q.QuizId = s.QuizId " +
                "WHERE s.QuizId = @quizId AND u.Role = 'Student' " +
                "GROUP BY s.UserId, s.QuizId, u.FullName, q.Title " +
                "ORDER BY MAX(s.Points) DESC, MIN(s.TakenAt) ASC", con))
            {
                cmd.Parameters.AddWithValue("@top", top);
                cmd.Parameters.AddWithValue("@quizId", quizId);
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read())
                        list.Add(new Score
                        {
                            ScoreId = (int)r["ScoreId"],
                            UserId = (int)r["UserId"],
                            QuizId = (int)r["QuizId"],
                            Points = (int)r["Points"],
                            TakenAt = (DateTime)r["TakenAt"],
                            FullName = (string)r["FullName"],
                            QuizTitle = (string)r["QuizTitle"]
                        });
            }
            return list;
        }

        // Every score a single user has recorded, newest attempt first.
        // Used by the personal "My Progress" page.
        public List<Score> GetScoresByUser(int userId)
        {
            var list = new List<Score>();
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT s.ScoreId, s.UserId, s.QuizId, s.Points, s.TakenAt, " +
                "       u.FullName, q.Title AS QuizTitle " +
                "FROM Scores s " +
                "JOIN Users u   ON u.UserId = s.UserId " +
                "JOIN Quizzes q ON q.QuizId = s.QuizId " +
                "WHERE s.UserId = @uid " +
                "ORDER BY s.TakenAt DESC", con))
            {
                cmd.Parameters.AddWithValue("@uid", userId);
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read())
                        list.Add(new Score
                        {
                            ScoreId = (int)r["ScoreId"],
                            UserId = (int)r["UserId"],
                            QuizId = (int)r["QuizId"],
                            Points = (int)r["Points"],
                            TakenAt = (DateTime)r["TakenAt"],
                            FullName = (string)r["FullName"],
                            QuizTitle = (string)r["QuizTitle"]
                        });
            }
            return list;
        }

        // Staff monitoring: every Student-role user with aggregates over their
        // attempts. LEFT JOIN keeps zero-attempt students (they sort last because
        // SQL Server puts NULL SUMs at the bottom of a DESC order).
        public List<StudentProgressRow> GetStudentProgress()
        {
            var list = new List<StudentProgressRow>();
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT u.UserId, u.FullName, u.Username, " +
                "       COUNT(DISTINCT s.QuizId) AS QuizzesAttempted, " +
                "       COUNT(s.ScoreId) AS TotalAttempts, " +
                "       ISNULL(MAX(s.Points), 0) AS BestScore, " +
                "       ISNULL(SUM(s.Points), 0) AS TotalPoints, " +
                "       MAX(s.TakenAt) AS LastActive " +
                "FROM Users u LEFT JOIN Scores s ON s.UserId = u.UserId " +
                "WHERE u.Role = 'Student' " +
                "GROUP BY u.UserId, u.FullName, u.Username " +
                "ORDER BY SUM(s.Points) DESC, u.FullName ASC", con))
            {
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read())
                        list.Add(new StudentProgressRow
                        {
                            UserId = (int)r["UserId"],
                            FullName = (string)r["FullName"],
                            Username = (string)r["Username"],
                            QuizzesAttempted = (int)r["QuizzesAttempted"],
                            TotalAttempts = (int)r["TotalAttempts"],
                            BestScore = (int)r["BestScore"],
                            TotalPoints = (int)r["TotalPoints"],
                            LastActive = r["LastActive"] == DBNull.Value
                                ? (DateTime?)null : (DateTime)r["LastActive"]
                        });
            }
            return list;
        }
    }
}
