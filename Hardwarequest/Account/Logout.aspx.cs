using System;

namespace Hardwarequest.Account
{
    public partial class Logout : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            AuthHelper.SignOut();
            Response.Redirect("~/");
        }
    }
}
