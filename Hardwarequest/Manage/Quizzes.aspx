<%@ Page Title="My Quizzes" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Quizzes.aspx.cs" Inherits="Hardwarequest.Manage.Quizzes" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h2 class="hq-title mb-0">My Quizzes</h2>
      <a class="btn hq-btn" href='<%= ResolveUrl("~/Quiz/Builder") %>'>New quiz</a>
    </div>
    <asp:Label ID="lblEmpty" runat="server" Visible="false" CssClass="d-block"
      Text="You have not created any quizzes yet." />
    <asp:Repeater ID="rpt" runat="server" OnItemCommand="rpt_ItemCommand">
      <HeaderTemplate><div class="row row-cols-1 row-cols-md-2 g-3"></HeaderTemplate>
      <ItemTemplate>
        <div class="col"><div class="card h-100 m-0 p-3 d-flex flex-column">
          <div class="d-flex justify-content-between align-items-start mb-1">
            <h3 class="h5 mb-0"><%# Server.HtmlEncode((string)Eval("Title")) %> <%# DraftBadge(Eval("IsPublished")) %></h3>
            <span class='badge <%# BadgeClass(Eval("Difficulty")) %>'><%# Server.HtmlEncode((string)Eval("Difficulty")) %></span>
          </div>
          <p class="text-muted small mb-2"><%# OwnerLabel(Eval("OwnerName")) %></p>
          <p class="mb-3"><%# SummaryText(Eval("AttemptCount"), Eval("StudentCount"), Eval("AvgAccuracy")) %></p>
          <div class="mt-auto btn-group btn-group-sm w-100" role="group">
            <a class="btn btn-outline-primary" href='<%# ResolveUrl("~/Manage/QuizStats?id=" + Eval("QuizId")) %>'>Stats</a>
            <a class="btn btn-outline-warning" href='<%# ResolveUrl("~/Quiz/Leaderboard?quizId=" + Eval("QuizId")) %>'>Leaderboard</a>
            <a class="btn btn-outline-success" href='<%# ResolveUrl("~/Quiz/Builder?id=" + Eval("QuizId")) %>'>Edit</a>
            <asp:Button runat="server" CssClass="btn btn-outline-danger" Text="Delete"
              CommandName="DeleteQuiz" CommandArgument='<%# Eval("QuizId") %>'
              OnClientClick="return hqConfirm(this,'Delete this quiz and all its questions?');" />
          </div>
        </div></div>
      </ItemTemplate>
      <FooterTemplate></div></FooterTemplate>
    </asp:Repeater>
  </div>
</asp:Content>
