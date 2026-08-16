using System;
using System.Collections.Generic;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Hardware
{
    public partial class Details : System.Web.UI.Page
    {
        // PartKeys that have a 3D model in Scripts/partmodels.js. Deliberately
        // duplicated from the JS registry so pages without a model never load
        // Three.js at all.
        private static readonly HashSet<string> ModelKeys = new HashSet<string>
        { "cpu", "motherboard", "ram", "gpu", "psu", "ssd", "case" };

        private readonly HardwareRepository _repo = new HardwareRepository();

        protected bool HasModel { get; private set; }
        protected string PartKeyJs { get; private set; } = "";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack) return;

            int id;
            if (!int.TryParse(Request.QueryString["id"], out id))
            {
                Response.Redirect("~/Hardware/List");
                return;
            }

            HardwareComponent c = _repo.GetById(id);
            if (c == null)
            {
                Response.Redirect("~/Hardware/List");
                return;
            }

            litName.Text = Server.HtmlEncode(c.Name);
            litDesc.Text = Server.HtmlEncode(c.ChildDescription);
            imgPart.ImageUrl = GetImage(c);
            imgPart.AlternateText = c.Name;

            string key = (c.PartKey ?? "").Trim().ToLowerInvariant();
            if (ModelKeys.Contains(key))
            {
                HasModel = true;
                PartKeyJs = key;
                // Hide the photo with CSS (not Visible=false) so it stays in the
                // HTML for the JS fallback when the 3D viewer fails to start.
                imgPart.CssClass += " d-none";
            }
        }

        // Uploaded photo, else the pre-rendered 3D snapshot (matches the list
        // page thumbnails and the WebGL-failure fallback), else the placeholder.
        private string GetImage(HardwareComponent c)
        {
            if (!string.IsNullOrEmpty(c.ImagePath)) return ResolveUrl(c.ImagePath);

            string key = (c.PartKey ?? "").Trim().ToLowerInvariant();
            if (key.Length > 0)
            {
                string snap = "~/Content/partsnaps/" + key + ".png";
                if (System.IO.File.Exists(Server.MapPath(snap)))
                    return ResolveUrl(snap);
            }
            return ResolveUrl("~/Content/placeholder.svg");
        }
    }
}
