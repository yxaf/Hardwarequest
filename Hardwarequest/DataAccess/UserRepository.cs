using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using Hardwarequest.Models;

namespace Hardwarequest.DataAccess
{
    public class UserRepository
    {
        // Returns the user with this username, or null if not found.
        public User GetByUsername(string username)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT UserId, Username, Email, FullName, PasswordHash, PasswordSalt, Role, CreatedAt " +
                "FROM Users WHERE Username = @u", con))
            {
                cmd.Parameters.AddWithValue("@u", username);
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    return r.Read() ? Map(r) : null;
            }
        }

        public bool UsernameExists(string username)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand("SELECT COUNT(1) FROM Users WHERE Username=@u", con))
            {
                cmd.Parameters.AddWithValue("@u", username);
                con.Open();
                return (int)cmd.ExecuteScalar() > 0;
            }
        }

        public bool EmailExists(string email)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand("SELECT COUNT(1) FROM Users WHERE Email=@e", con))
            {
                cmd.Parameters.AddWithValue("@e", email);
                con.Open();
                return (int)cmd.ExecuteScalar() > 0;
            }
        }

        // Inserts a user; returns the new UserId.
        public int Create(User u)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "INSERT INTO Users (Username, Email, FullName, PasswordHash, PasswordSalt, Role) " +
                "VALUES (@u, @e, @f, @h, @s, @r); SELECT CAST(SCOPE_IDENTITY() AS INT);", con))
            {
                cmd.Parameters.AddWithValue("@u", u.Username);
                cmd.Parameters.AddWithValue("@e", u.Email);
                cmd.Parameters.AddWithValue("@f", u.FullName);
                cmd.Parameters.AddWithValue("@h", u.PasswordHash);
                cmd.Parameters.AddWithValue("@s", u.PasswordSalt);
                cmd.Parameters.AddWithValue("@r", u.Role);
                con.Open();
                return (int)cmd.ExecuteScalar();
            }
        }

        public List<User> GetAll()
        {
            var list = new List<User>();
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT UserId, Username, Email, FullName, PasswordHash, PasswordSalt, Role, CreatedAt " +
                "FROM Users ORDER BY CreatedAt DESC", con))
            {
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read()) list.Add(Map(r));
            }
            return list;
        }

        // Hashes the password with a fresh salt and stores both.
        public void SetPassword(string username, string password)
        {
            string salt = PasswordHasher.NewSalt();
            string hash = PasswordHasher.Hash(password, salt);

            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "UPDATE Users SET PasswordHash=@h, PasswordSalt=@s WHERE Username=@u", con))
            {
                cmd.Parameters.AddWithValue("@h", hash);
                cmd.Parameters.AddWithValue("@s", salt);
                cmd.Parameters.AddWithValue("@u", username);
                con.Open();
                cmd.ExecuteNonQuery();
            }
        }

        public void UpdateRole(int userId, string role)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand("UPDATE Users SET Role=@r WHERE UserId=@id", con))
            {
                cmd.Parameters.AddWithValue("@r", role);
                cmd.Parameters.AddWithValue("@id", userId);
                con.Open();
                cmd.ExecuteNonQuery();
            }
        }

        // True when a DIFFERENT user already uses this email (profile edits must
        // not trip over the user's own row).
        public bool EmailInUseByOther(string email, int userId)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT COUNT(1) FROM Users WHERE Email=@e AND UserId<>@id", con))
            {
                cmd.Parameters.AddWithValue("@e", email);
                cmd.Parameters.AddWithValue("@id", userId);
                con.Open();
                return (int)cmd.ExecuteScalar() > 0;
            }
        }

        public void UpdateProfile(int userId, string fullName, string email)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "UPDATE Users SET FullName=@f, Email=@e WHERE UserId=@id", con))
            {
                cmd.Parameters.AddWithValue("@f", fullName);
                cmd.Parameters.AddWithValue("@e", email);
                cmd.Parameters.AddWithValue("@id", userId);
                con.Open();
                cmd.ExecuteNonQuery();
            }
        }

        private static User Map(IDataRecord r) => new User
        {
            UserId = (int)r["UserId"],
            Username = (string)r["Username"],
            Email = (string)r["Email"],
            FullName = (string)r["FullName"],
            PasswordHash = (string)r["PasswordHash"],
            PasswordSalt = (string)r["PasswordSalt"],
            Role = (string)r["Role"],
            CreatedAt = (System.DateTime)r["CreatedAt"]
        };
    }
}
