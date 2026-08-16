using System;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using Hardwarequest.DataAccess;

namespace Hardwarequest.Explore
{
    public partial class Explorer : System.Web.UI.Page
    {
        // JSON map partKey -> { name, desc, url } consumed by the page script.
        protected string PartsJson = "{}";

        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                var map = new Dictionary<string, object>();
                foreach (var part in new HardwareRepository().GetAll())
                {
                    if (string.IsNullOrWhiteSpace(part.PartKey)) continue;
                    // Learn-more links point into the login-only Hardware
                    // section, so visitors don't get the button at all.
                    map[part.PartKey.Trim().ToLowerInvariant()] = new
                    {
                        name = part.Name,
                        desc = part.ChildDescription,
                        url = Request.IsAuthenticated
                            ? ResolveUrl("~/Hardware/Details.aspx?id=" + part.Id)
                            : null
                    };
                }
                PartsJson = new JavaScriptSerializer().Serialize(map);
            }
            catch (Exception)
            {
                PartsJson = "{}"; // the explorer must never break because of data
            }
        }
    }
}
