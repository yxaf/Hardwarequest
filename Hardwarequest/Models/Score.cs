using System;

namespace Hardwarequest.Models
{
    // Plain data class mirroring the Scores table (a leaderboard entry).
    public class Score
    {
        public int ScoreId { get; set; }
        public int UserId { get; set; }
        public int QuizId { get; set; }
        public int Points { get; set; }
        public DateTime TakenAt { get; set; }

        // Not columns: filled in by leaderboard queries that join Users/Quizzes.
        public string FullName { get; set; }
        public string QuizTitle { get; set; }
    }
}
