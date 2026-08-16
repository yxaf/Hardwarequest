namespace Hardwarequest.Models
{
    // Plain data class mirroring the Questions table.
    // Four options (A-D); CorrectOption holds the letter of the right one.
    public class Question
    {
        public int QuestionId { get; set; }
        public int QuizId { get; set; }
        public string Text { get; set; }
        public string OptionA { get; set; }
        public string OptionB { get; set; }
        public string OptionC { get; set; }
        public string OptionD { get; set; }
        public char CorrectOption { get; set; }   // 'A' | 'B' | 'C' | 'D'
    }
}
