using System;
using Hardwarequest.DataAccess;

namespace Hardwarequest.Manage
{
    public partial class Default : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!AuthHelper.IsStaff) { Response.Redirect("~/Default"); return; }

            bool isAdmin = AuthHelper.IsInRole(Models.UserRole.Administrator);
            int? uid = AuthHelper.CurrentUserId;
            litScope.Text = isAdmin ? "You are an administrator, so you can see everyone's content." : "";

            litQuizzes.Text = new QuizRepository().GetQuizzesForManager(uid, isAdmin).Count.ToString();
            litTopics.Text = new TopicRepository().GetTopicsForManager(uid, isAdmin).Count.ToString();
            litThreads.Text = new ForumRepository().GetThreadsForManager(uid, isAdmin).Count.ToString();
        }
    }
}
