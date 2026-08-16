using System;
using System.Text;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Manage
{
    public partial class QuizStats : System.Web.UI.Page
    {
        // Exposed to the roster markup for the "best/max" column.
        protected int MaxPoints;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!AuthHelper.IsStaff) { Response.Redirect("~/Default"); return; }

            int id;
            if (!int.TryParse(Request.QueryString["id"], out id)) { Response.Redirect("~/Manage/Quizzes"); return; }

            var stats = new QuizRepository().GetQuizStats(id);
            if (stats == null) { Response.Redirect("~/Manage/Quizzes"); return; }

            // A lecturer may only view stats for quizzes they own.
            if (!AuthHelper.CanManage(stats.CreatedByUserId)) { Response.Redirect("~/Manage/Quizzes"); return; }

            MaxPoints = stats.MaxPoints;
            litTitle.Text = Server.HtmlEncode(stats.Title);
            litAttempts.Text = stats.AttemptCount.ToString();
            litStudents.Text = stats.StudentCount.ToString();
            litAccuracy.Text = (int)Math.Round(stats.AvgAccuracy * 100) + "%";
            litBest.Text = stats.BestPoints + "/" + stats.MaxPoints;
            litLast.Text = stats.LastTaken.HasValue ? stats.LastTaken.Value.ToString("yyyy-MM-dd") : "-";

            rptRoster.DataSource = stats.Roster;
            rptRoster.DataBind();
            lblNoStudents.Visible = stats.Roster.Count == 0;

            if (stats.AttemptCount > 0)
            {
                phCharts.Visible = true;
                hfChartData.Value = BuildChartJson(stats);
            }
        }

        // Hand-built JSON (no serializer dependency) for the two charts.
        private static string BuildChartJson(Models.QuizStats s)
        {
            var sb = new StringBuilder();
            sb.Append("{\"dist\":[");
            for (int i = 0; i < s.Distribution.Length; i++)
            { if (i > 0) sb.Append(','); sb.Append(s.Distribution[i]); }
            sb.Append("],\"timeLabels\":[");
            for (int i = 0; i < s.Timeline.Count; i++)
            { if (i > 0) sb.Append(','); sb.Append('"').Append(s.Timeline[i].Day.ToString("yyyy-MM-dd")).Append('"'); }
            sb.Append("],\"timeCounts\":[");
            for (int i = 0; i < s.Timeline.Count; i++)
            { if (i > 0) sb.Append(','); sb.Append(s.Timeline[i].Count); }
            sb.Append("]}");
            return sb.ToString();
        }
    }
}
