using System;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Account
{
    // Named UserProfile (not Profile) so it can't collide with Page.Profile.
    public partial class UserProfile : System.Web.UI.Page
    {
        private readonly UserRepository _users = new UserRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            // Account/ stays open for Login/Register, so this page gates itself.
            if (!AuthHelper.IsLoggedIn)
            { Response.Redirect("~/Account/Login"); return; }

            if (IsPostBack) return;

            User me = _users.GetByUsername(AuthHelper.CurrentUsername);
            if (me == null) { Response.Redirect("~/Account/Login"); return; }

            litUsername.Text = Server.HtmlEncode(me.Username);
            litRole.Text = Server.HtmlEncode(me.Role);
            txtFullName.Text = me.FullName;
            txtEmail.Text = me.Email;
        }

        protected void btnSaveDetails_Click(object sender, EventArgs e)
        {
            Validate("details");
            if (!IsValid) return;

            User me = _users.GetByUsername(AuthHelper.CurrentUsername);
            if (me == null) { Response.Redirect("~/Account/Login"); return; }

            string fullName = txtFullName.Text.Trim();
            string email = txtEmail.Text.Trim();

            if (_users.EmailInUseByOther(email, me.UserId))
            {
                ShowMsg(lblDetailsMsg, "That email is already used by another account.", false);
                return;
            }

            _users.UpdateProfile(me.UserId, fullName, email);
            AuthHelper.RefreshFullName(fullName);
            ShowMsg(lblDetailsMsg, "Your details have been updated.", true);
        }

        protected void btnChangePassword_Click(object sender, EventArgs e)
        {
            Validate("password");
            if (!IsValid) return;

            User me = _users.GetByUsername(AuthHelper.CurrentUsername);
            if (me == null) { Response.Redirect("~/Account/Login"); return; }

            if (!PasswordHasher.VerifyAny(txtCurrent.Text, me.PasswordSalt, me.PasswordHash))
            {
                ShowMsg(lblPasswordMsg, "Current password is incorrect.", false);
                return;
            }

            // Stores a fresh salt and hash, so this also upgrades a row that was
            // still holding plain text.
            _users.SetPassword(me.Username, txtNew.Text);
            ShowMsg(lblPasswordMsg, "Your password has been changed.", true);
        }

        private static void ShowMsg(System.Web.UI.WebControls.Label lbl, string text, bool ok)
        {
            lbl.Text = text;
            lbl.CssClass = (ok ? "text-success" : "text-danger") + " d-block mb-2";
        }
    }
}
