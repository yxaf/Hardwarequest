using System;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Account
{
    public partial class Register : System.Web.UI.Page
    {
        private readonly UserRepository _users = new UserRepository();

        protected void btnRegister_Click(object sender, EventArgs e)
        {
            if (!IsValid) return; // client+server validators

            string username = txtUsername.Text.Trim();
            string email = txtEmail.Text.Trim();

            // Server-side re-checks (never trust the client).
            if (_users.UsernameExists(username))
            {
                lblError.Text = "That username is already taken.";
                return;
            }
            if (_users.EmailExists(email))
            {
                lblError.Text = "That email is already registered.";
                return;
            }

            // Only Student or Lecturer may be self-selected; anything else (e.g. a tampered
            // "Administrator") falls back to Student. Admins are still made via Admin/ManageUsers.
            string role = ddlRole.SelectedValue == UserRole.Lecturer
                ? UserRole.Lecturer
                : UserRole.Student;

            // The password is never stored as typed: a per-user random salt plus a
            // PBKDF2 hash go to the database instead.
            string salt = PasswordHasher.NewSalt();

            var user = new User
            {
                Username = username,
                Email = email,
                FullName = txtFullName.Text.Trim(),
                PasswordSalt = salt,
                PasswordHash = PasswordHasher.Hash(txtPassword.Text, salt),
                Role = role
            };
            _users.Create(user);

            // Sign in immediately, then go home.
            AuthHelper.SignIn(user.Username, user.Role, user.FullName);
            Response.Redirect("~/");
        }
    }
}
