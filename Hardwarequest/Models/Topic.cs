using System;

namespace Hardwarequest.Models
{
    // Plain data class mirroring the Topics table (a learning-material chapter).
    public class Topic
    {
        public int TopicId { get; set; }
        public string Title { get; set; }
        public string Body { get; set; }          // multi-paragraph lesson text
        public string ImagePath { get; set; }     // optional cover picture
        public int? CreatedByUserId { get; set; } // owner (admin or creating lecturer)
        public DateTime CreatedAt { get; set; }

        // Not a column: filled by manager queries that join the creator.
        public string OwnerName { get; set; }
    }
}
