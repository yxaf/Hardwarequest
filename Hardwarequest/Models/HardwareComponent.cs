using System;

namespace Hardwarequest.Models
{
    // Plain data class mirroring the HardwareComponents table.
    public class HardwareComponent
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string ChildDescription { get; set; }
        public string ImagePath { get; set; }   // app-relative, e.g. "~/Content/uploads/x.png" (nullable)
        public string PartKey { get; set; }      // links to a 3D part, e.g. "cpu" (nullable)
        public DateTime CreatedAt { get; set; }
    }
}
