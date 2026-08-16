using System;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Account
{
    public partial class Login : System.Web.UI.Page
    {
        private readonly UserRepository _users = new UserRepository();

        protected void btnLogin_Click(object sender, EventArgs e)
        {
            if (!IsValid) return;

            User user = _users.GetByUsername(txtUsername.Text.Trim());
            if (user == null ||
                !PasswordHasher.VerifyAny(txtPassword.Text, user.PasswordSalt, user.PasswordHash))
            {
                lblError.Text = "Wrong username or password.";
                return;
            }

            // Safety net for an account the startup migration missed (e.g. a database
            // swapped in while the app was running): the password just proved correct,
            // so re-save it hashed and never accept plain text for this row again.
            if (PasswordHasher.IsPlainText(user.PasswordSalt, user.PasswordHash))
                _users.SetPassword(user.Username, txtPassword.Text);

            AuthHelper.SignIn(user.Username, user.Role, user.FullName);

            // Return to the page that bounced us here, but only if it is a
            // local path (never an off-site redirect).
            string returnUrl = Request.QueryString["ReturnUrl"];
            bool isLocal = !string.IsNullOrEmpty(returnUrl) &&
                           (returnUrl.StartsWith("~/") ||
                            (returnUrl.StartsWith("/") && !returnUrl.StartsWith("//") && !returnUrl.StartsWith("/\\")));
            Response.Redirect(isLocal ? returnUrl : "~/");
        }
    }
}
