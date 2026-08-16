using System;

namespace Hardwarequest.Models
{
    // Plain data class mirroring the ForumPosts table.
    // A thread's opening message is simply its first ForumPost row.
    public class ForumPost
    {
        public int PostId { get; set; }
        public int ThreadId { get; set; }
        public int UserId { get; set; }
        public string Body { get; set; }
        public DateTime CreatedAt { get; set; }

        // Not a column: filled in by queries that join Users for display.
        public string AuthorName { get; set; }
    }
}
