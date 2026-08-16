using System;
using System.Collections.Generic;
using System.Linq;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Quiz
{
    // Personal dashboard: the logged-in user's own quiz scores and summary stats.
    // The Quiz area already blocks anonymous users in Web.config, so anyone
    // reaching this page is authenticated.
    public partial class MyProgress : System.Web.UI.Page
    {
        private readonly QuizRepository _quizRepo = new QuizRepository();
        private readonly UserRepository _userRepo = new UserRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            // Staff monitor students instead of tracking their own progress.
            if (AuthHelper.IsStaff)
            { Response.Redirect("~/Quiz/StudentProgress"); return; }

            if (IsPostBack) return;

            User me = _userRepo.GetByUsername(AuthHelper.CurrentUsername);
            List<Score> scores = me != null
                ? _quizRepo.GetScoresByUser(me.UserId)
                : new List<Score>();

            bool hasScores = scores.Count > 0;
            phStats.Visible = hasScores;
            lblEmpty.Visible = !hasScores;
            lnkTakeQuiz.Visible = !hasScores;
            if (!hasScores) return;

            // Distinct quizzes attempted, best single result, and lifetime points.
            litQuizzes.Text = scores.Select(s => s.QuizId).Distinct().Count().ToString();
            litBest.Text = scores.Max(s => s.Points).ToString();
            litTotal.Text = scores.Sum(s => s.Points).ToString();

            rptScores.DataSource = scores;
            rptScores.DataBind();
        }
    }
}
