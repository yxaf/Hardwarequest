using System;
using System.IO;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Hardware
{
    public partial class Create : System.Web.UI.Page
    {
        private readonly HardwareRepository _repo = new HardwareRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            // Administrators only.
            if (!AuthHelper.IsAdmin) Response.Redirect("~/");
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            if (!IsValid) return;

            string imagePath;
            if (!ImageUpload.TrySave(fileImage, out imagePath, out string error))
            {
                lblError.Text = error;
                return;
            }

            var c = new HardwareComponent
            {
                Name = txtName.Text.Trim(),
                ChildDescription = txtDesc.Text.Trim(),
                PartKey = string.IsNullOrWhiteSpace(txtPartKey.Text) ? null : txtPartKey.Text.Trim(),
                ImagePath = imagePath
            };
            _repo.Create(c);
            Response.Redirect("~/Hardware/List");
        }
    }
}
