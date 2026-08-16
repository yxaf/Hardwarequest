using System;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Hardware
{
    public partial class Edit : System.Web.UI.Page
    {
        private readonly HardwareRepository _repo = new HardwareRepository();

        private int PartId
        {
            get { return int.TryParse(Request.QueryString["id"], out int i) ? i : 0; }
        }

        // Existing image path is remembered across the postback.
        private string CurrentImagePath
        {
            get { return ViewState["img"] as string; }
            set { ViewState["img"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!AuthHelper.IsAdmin) { Response.Redirect("~/"); return; }
            if (IsPostBack) return;

            HardwareComponent c = _repo.GetById(PartId);
            if (c == null) { Response.Redirect("~/Hardware/List"); return; }

            txtName.Text = c.Name;
            txtDesc.Text = c.ChildDescription;
            txtPartKey.Text = c.PartKey;
            CurrentImagePath = c.ImagePath;
            imgCurrent.ImageUrl = ResolveUrl(string.IsNullOrEmpty(c.ImagePath)
                ? "~/Content/placeholder.svg" : c.ImagePath);
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            if (!IsValid) return;

            string imagePath = CurrentImagePath;
            if (!ImageUpload.TrySave(fileImage, out string uploaded, out string error))
            {
                lblError.Text = error;
                return;
            }
            if (uploaded != null) imagePath = uploaded; // replace only when a new file was sent

            var c = new HardwareComponent
            {
                Id = PartId,
                Name = txtName.Text.Trim(),
                ChildDescription = txtDesc.Text.Trim(),
                PartKey = string.IsNullOrWhiteSpace(txtPartKey.Text) ? null : txtPartKey.Text.Trim(),
                ImagePath = imagePath
            };
            _repo.Update(c);
            Response.Redirect("~/Hardware/List");
        }
    }
}
