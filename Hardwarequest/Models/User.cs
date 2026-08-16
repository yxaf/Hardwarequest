using System;

namespace Hardwarequest.Models
{
    // Plain data class mirroring the Users table. No logic here.
    public class User
    {
        public int UserId { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }
        public string FullName { get; set; }
        public string PasswordHash { get; set; }
        public string PasswordSalt { get; set; }
        public string Role { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    // The three real roles. "Visitor" is simply "not logged in", so it is not stored.
    public static class UserRole
    {
        public const string Student = "Student";
        public const string Lecturer = "Lecturer";
        public const string Administrator = "Administrator";
    }
}
