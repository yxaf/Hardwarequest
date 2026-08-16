using System;
using System.Collections.Generic;

namespace Hardwarequest.Models
{
    // Row for the Manage > My Quizzes list: quiz fields + usage aggregates + owner.
    public class QuizManageRow
    {
        public int QuizId { get; set; }
        public string Title { get; set; }
        public string Difficulty { get; set; }
        public int QuestionCount { get; set; }
        public int AttemptCount { get; set; }
        public int StudentCount { get; set; }
        public double AvgAccuracy { get; set; }   // 0..1
        public int? CreatedByUserId { get; set; }
        public string OwnerName { get; set; }
        public bool IsPublished { get; set; }
    }

    // One student's record on a quiz (their best attempt + activity).
    public class StudentStatRow
    {
        public string FullName { get; set; }
        public int Attempts { get; set; }
        public int BestPoints { get; set; }
        public double BestAccuracy { get; set; }  // 0..1
        public DateTime LastTaken { get; set; }
    }

    // One day of attempt activity (for the timeline chart).
    public class TimelinePoint
    {
        public DateTime Day { get; set; }
        public int Count { get; set; }
    }

    // Full statistics for one quiz's Stats page.
    public class QuizStats
    {
        public int QuizId { get; set; }
        public string Title { get; set; }
        public string Difficulty { get; set; }
        public int QuestionCount { get; set; }
        public int Weight { get; set; }
        public int MaxPoints { get; set; }
        public int? CreatedByUserId { get; set; }

        public int AttemptCount { get; set; }
        public int StudentCount { get; set; }
        public int BestPoints { get; set; }
        public double AvgAccuracy { get; set; }   // 0..1
        public DateTime? LastTaken { get; set; }

        public List<StudentStatRow> Roster { get; set; } = new List<StudentStatRow>();
        public int[] Distribution { get; set; } = new int[5]; // buckets 0/25/50/75/100%
        public List<TimelinePoint> Timeline { get; set; } = new List<TimelinePoint>();
    }
}
