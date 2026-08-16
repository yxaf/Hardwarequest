using System;
using System.Security.Cryptography;

namespace Hardwarequest.DataAccess
{
    // PBKDF2 (Rfc2898DeriveBytes) password hashing. Built into .NET, no packages.
    public static class PasswordHasher
    {
        private const int SaltBytes = 16;
        private const int HashBytes = 32;
        private const int Iterations = 100_000;

        // Returns a new random salt as Base64.
        public static string NewSalt()
        {
            byte[] salt = new byte[SaltBytes];
            using (var rng = RandomNumberGenerator.Create())
                rng.GetBytes(salt);
            return Convert.ToBase64String(salt);
        }

        // Hashes the password with the given Base64 salt; returns Base64 hash.
        public static string Hash(string password, string base64Salt)
        {
            byte[] salt = Convert.FromBase64String(base64Salt);
            using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, Iterations, HashAlgorithmName.SHA256))
                return Convert.ToBase64String(pbkdf2.GetBytes(HashBytes));
        }

        // Constant-time comparison of a candidate password against a stored hash.
        public static bool Verify(string password, string base64Salt, string expectedBase64Hash)
        {
            string actual = Hash(password, base64Salt);
            byte[] a = Convert.FromBase64String(actual);
            byte[] b = Convert.FromBase64String(expectedBase64Hash);
            if (a.Length != b.Length) return false;
            int diff = 0;
            for (int i = 0; i < a.Length; i++) diff |= a[i] ^ b[i];
            return diff == 0;
        }

        // True when the stored value cannot have come from Hash(): either there is no
        // salt, or the stored text does not decode to a hash-sized digest. Rows written
        // while hashing was disabled look like this and hold the password as plain text,
        // so callers use this to spot them and re-save a real hash.
        public static bool IsPlainText(string base64Salt, string storedHash)
        {
            if (string.IsNullOrEmpty(base64Salt)) return true;
            try { return Convert.FromBase64String(storedHash ?? "").Length != HashBytes; }
            catch (FormatException) { return true; }
        }

        // Verifies against either storage format, so a not-yet-migrated account can
        // still sign in once. Callers MUST upgrade the row when IsPlainText is true.
        // A salt too corrupt to decode fails the check rather than throwing.
        public static bool VerifyAny(string password, string base64Salt, string stored)
        {
            if (IsPlainText(base64Salt, stored))
                return string.Equals(password, stored, StringComparison.Ordinal);

            try { return Verify(password, base64Salt, stored); }
            catch (FormatException) { return false; }
        }
    }
}
