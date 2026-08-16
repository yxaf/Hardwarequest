using System;
using System.Web.UI.WebControls;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Forum
{
    public partial class Thread : System.Web.UI.Page
    {
        private readonly ForumRepository _repo = new ForumRepository();
        private readonly UserRepository _users = new UserRepository();

        protected bool IsStaff => AuthHelper.IsStaff;

        private int ThreadId
        {
            get { return int.TryParse(Request.QueryString["id"], out int i) ? i : 0; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            ForumThread t = _repo.GetThreadById(ThreadId);
            if (t == null) { Response.Redirect("~/Forum/List"); return; }

            litTitle.Text = Server.HtmlEncode(t.Title);
            litAuthor.Text = Server.HtmlEncode(t.AuthorName);

            // Reading is public; only logged-in users get the reply box.
            pnlReply.Visible = AuthHelper.IsLoggedIn;
            pnlLoginHint.Visible = !AuthHelper.IsLoggedIn;

            if (!IsPostBack) Bind();
        }

        private void Bind()
        {
            rptPosts.DataSource = _repo.GetPosts(ThreadId);
            rptPosts.DataBind();
        }

        protected void btnReply_Click(object sender, EventArgs e)
        {
            if (!IsValid || !AuthHelper.IsLoggedIn) return;

            User u = _users.GetByUsername(AuthHelper.CurrentUsername);
            if (u == null) { Response.Redirect("~/Account/Login"); return; }

            _repo.AddPost(ThreadId, u.UserId, txtBody.Text.Trim());
            txtBody.Text = "";
            Bind();
        }

        // Whether the current user may delete this post (admin or its author).
        protected bool CanManage(object userId) =>
            AuthHelper.CanManage(userId as int?);

        protected void rptPosts_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            // Re-check ownership server-side (button is only hidden, not secured).
            if (e.CommandName == "DeletePost")
            {
                int postId = int.Parse((string)e.CommandArgument);
                ForumPost post = _repo.GetPosts(ThreadId).Find(p => p.PostId == postId);
                if (post == null || !AuthHelper.CanManage(post.UserId)) return;

                _repo.DeletePost(postId);
                // If that removed the last post, the thread is empty: drop it too.
                if (_repo.CountPosts(ThreadId) == 0)
                {
                    _repo.DeleteThread(ThreadId);
                    Response.Redirect("~/Forum/List");
                    return;
                }
                Bind();
            }
        }
    }
}
