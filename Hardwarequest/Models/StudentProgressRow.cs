using System;

namespace Hardwarequest.Models
{
    // One row of the staff Student Progress table: a Student-role user plus
    // aggregates over all their quiz attempts (zeros when they have none).
    public class StudentProgressRow
    {
        public int UserId { get; set; }
        public string FullName { get; set; }
        public string Username { get; set; }
        public int QuizzesAttempted { get; set; }
        public int TotalAttempts { get; set; }
        public int BestScore { get; set; }
        public int TotalPoints { get; set; }
        public DateTime? LastActive { get; set; }

        public string LastActiveText =>
            LastActive.HasValue ? LastActive.Value.ToString("d MMM yyyy, h:mm tt") : "—";

        public bool HasAttempts => TotalAttempts > 0;
    }
}
