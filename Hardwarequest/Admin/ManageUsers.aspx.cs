using System;
using System.Web.UI.WebControls;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Admin
{
    public partial class ManageUsers : System.Web.UI.Page
    {
        private readonly UserRepository _users = new UserRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            // Defense in depth: Web.config <location> already blocks anonymous users,
            // but re-check the exact role here too (role lives in session).
            if (!AuthHelper.IsInRole(UserRole.Administrator))
            {
                Response.Redirect("~/");
                return;
            }
            if (!IsPostBack) BindGrid();
        }

        private void BindGrid()
        {
            gvUsers.DataSource = _users.GetAll();
            gvUsers.DataBind();
        }

        // Builds the OnClientClick that routes the role buttons through the
        // site's custom confirm popup. JavaScriptStringEncode keeps a username
        // with quotes from breaking out of the script/attribute.
        protected string RoleConfirmJs(object username, string role)
        {
            string msg = "Change " + username + "'s role to " + role + "?";
            return "return hqConfirm(this, " +
                System.Web.HttpUtility.JavaScriptStringEncode(msg, true) + ");";
        }

        protected void gvUsers_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            int userId = int.Parse((string)e.CommandArgument);
            switch (e.CommandName)
            {
                case "MakeStudent":  _users.UpdateRole(userId, UserRole.Student); break;
                case "MakeLecturer": _users.UpdateRole(userId, UserRole.Lecturer); break;
                case "MakeAdmin":    _users.UpdateRole(userId, UserRole.Administrator); break;
                default: return;
            }
            BindGrid();
        }
    }
}
