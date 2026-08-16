using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Optimization;
using System.Web.Routing;
using System.Web.Security;
using System.Web.SessionState;

namespace Hardwarequest
{
    public class Global : HttpApplication
    {
        // Auth cookies issued before this run are rejected (see below), so every
        // fresh run (F5 / IIS restart) starts logged out.
        private static DateTime _appStartUtc;

        void Application_Start(object sender, EventArgs e)
        {
            _appStartUtc = DateTime.UtcNow;

            // Code that runs on application startup
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);

            // Apply any post-deploy schema additions to an existing database, then
            // fill an empty database with demo content so the app is usable on first run.
            DataAccess.Db.EnsureSchema();
            DataAccess.DataSeeder.SeedIfEmpty();
        }

        void Application_PostAuthenticateRequest(object sender, EventArgs e)
        {
            FormsIdentity id = Context.User == null ? null : Context.User.Identity as FormsIdentity;
            if (id == null) return;

            // Ticket predates this app run: treat the request as anonymous and
            // clear the stale cookie so the login state doesn't survive restarts.
            if (id.Ticket.IssueDate.ToUniversalTime() < _appStartUtc)
            {
                FormsAuthentication.SignOut();
                Context.User = new System.Security.Principal.GenericPrincipal(
                    new System.Security.Principal.GenericIdentity(""), new string[0]);
            }
        }
    }
}