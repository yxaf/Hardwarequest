using System;

namespace Hardwarequest.Models
{
    // Plain data class mirroring the ForumThreads table.
    public class ForumThread
    {
        public int ThreadId { get; set; }
        public string Title { get; set; }
        public int CreatedByUserId { get; set; }
        public DateTime CreatedAt { get; set; }

        // Not columns: filled in by list queries that join Users / count posts.
        public string AuthorName { get; set; }
        public int ReplyCount { get; set; }
        public DateTime LastActivity { get; set; }
    }
}
