using System;
using System.Web.UI.WebControls;
using Hardwarequest.DataAccess;

namespace Hardwarequest.Hardware
{
    public partial class List : System.Web.UI.Page
    {
        private readonly HardwareRepository _repo = new HardwareRepository();

        // Exposed to the markup data-binding expressions.
        protected bool IsAdmin => AuthHelper.IsAdmin;

        protected void Page_Load(object sender, EventArgs e)
        {
            phStaffActions.Visible = IsAdmin;
            if (!IsPostBack) Bind();
        }

        private void Bind()
        {
            // Empty term => Search returns everything, so this covers both cases.
            var items = _repo.Search(txtSearch.Text);
            rptParts.DataSource = items;
            rptParts.DataBind();
            lblEmpty.Visible = items.Count == 0;
            lblEmpty.Text = string.IsNullOrWhiteSpace(txtSearch.Text)
                ? "No parts yet. Check back soon! "
                : "No parts match your search.";
        }

        protected void btnSearch_Click(object sender, EventArgs e) => Bind();

        protected void btnClear_Click(object sender, EventArgs e)
        {
            txtSearch.Text = "";
            Bind();
        }

        // Returns a resolvable image URL. Parts without an uploaded photo fall
        // back to the pre-rendered snapshot of their 3D model (the same model
        // the Details page shows), then to the generic placeholder.
        protected string GetImage(object path, object partKey)
        {
            string p = path as string;
            if (!string.IsNullOrEmpty(p)) return ResolveUrl(p);

            string key = ((partKey as string) ?? "").Trim().ToLowerInvariant();
            if (key.Length > 0)
            {
                string snap = "~/Content/partsnaps/" + key + ".png";
                if (System.IO.File.Exists(Server.MapPath(snap)))
                    return ResolveUrl(snap);
            }
            return ResolveUrl("~/Content/placeholder.svg");
        }

        protected void rptParts_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            // Re-check role server-side (the buttons are only hidden, not secured).
            if (e.CommandName == "DeletePart" && IsAdmin)
            {
                _repo.Delete(int.Parse((string)e.CommandArgument));
                Bind();
            }
        }
    }
}
