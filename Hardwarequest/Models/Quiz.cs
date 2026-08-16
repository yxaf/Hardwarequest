using System;

namespace Hardwarequest.Models
{
    // Plain data class mirroring the Quizzes table.
    public class Quiz
    {
        public int QuizId { get; set; }
        public string Title { get; set; }
        public string Difficulty { get; set; } // 'Easy' | 'Medium' | 'Hard'
        public string Description { get; set; } // optional blurb shown on the quiz card
        public string ImagePath { get; set; }   // optional cover picture (~/Content/uploads/...)
        public int? CreatedByUserId { get; set; } // owner; null for legacy quizzes (admin-managed)
        public bool IsPublished { get; set; }     // drafts are hidden from students

        // Not a column: filled in by some queries for display convenience.
        public int QuestionCount { get; set; }
    }

    // The three difficulty levels, plus the kid-friendly badge and point weight.
    public static class QuizDifficulty
    {
        public const string Easy = "Easy";
        public const string Medium = "Medium";
        public const string Hard = "Hard";

        // Coloured badge shown to children next to each quiz.
        public static string Badge(string difficulty)
        {
            switch (difficulty)
            {
                case Hard: return " Hard";
                case Medium: return " Medium";
                default: return " Easy";
            }
        }

        // Points earned per correct answer. Harder quizzes are worth more.
        public static int Weight(string difficulty)
        {
            switch (difficulty)
            {
                case Hard: return 3;
                case Medium: return 2;
                default: return 1;
            }
        }

        public static bool IsValid(string difficulty) =>
            difficulty == Easy || difficulty == Medium || difficulty == Hard;
    }
}
