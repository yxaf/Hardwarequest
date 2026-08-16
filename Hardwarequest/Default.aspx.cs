using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Hardwarequest
{
    public partial class _Default : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Visitor intro flow: the first time an anonymous visitor lands on
            // Home directly (startup page, typed URL, bookmark), show the
            // Inside the Machine story instead. Clicks from inside the site
            // carry a same-host Referer and must always reach Home on the
            // first click. Flag set before redirecting so Home renders
            // normally afterwards.
            if (!Request.IsAuthenticated && Session["IntroSeen"] == null)
            {
                Session["IntroSeen"] = true;

                Uri referrer = Request.UrlReferrer;
                bool cameFromThisSite = referrer != null &&
                    string.Equals(referrer.Host, Request.Url.Host, StringComparison.OrdinalIgnoreCase);
                if (!cameFromThisSite)
                {
                    Response.Redirect("~/Explore/InsideTheMachine");
                }
            }
        }
    }
}