using System;
using System.IO;
using System.Web;
using System.Web.UI.WebControls;

namespace Hardwarequest
{
    // Shared image-upload handling for hardware pages.
    public static class ImageUpload
    {
        private static readonly string[] Allowed = { ".png", ".jpg", ".jpeg", ".gif" };

        // Saves the uploaded image (if any) into ~/Content/uploads with a unique name.
        // appPath = app-relative path ("~/Content/uploads/x.png") or null when no file.
        // Returns false (with error) only on a real validation/upload problem.
        public static bool TrySave(FileUpload fileUpload, out string appPath, out string error)
        {
            appPath = null;
            error = null;

            if (fileUpload == null || !fileUpload.HasFile) return true;

            string ext = Path.GetExtension(fileUpload.FileName).ToLowerInvariant();
            if (Array.IndexOf(Allowed, ext) < 0)
            {
                error = "Picture must be a PNG, JPG or GIF.";
                return false;
            }

            string dir = HttpContext.Current.Server.MapPath("~/Content/uploads");
            Directory.CreateDirectory(dir);

            string fileName = Guid.NewGuid().ToString("N") + ext;
            fileUpload.SaveAs(Path.Combine(dir, fileName));
            appPath = "~/Content/uploads/" + fileName;
            return true;
        }
    }
}
