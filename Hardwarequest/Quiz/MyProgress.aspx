<%@ Page Title="My Progress" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="MyProgress.aspx.cs" Inherits="Hardwarequest.Quiz.MyProgress" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card">
    <h2 class="hq-title">My Progress </h2>
    <p>Your personal quiz history. Keep practising to climb the <a href="<%= ResolveUrl("~/Quiz/Leaderboard") %>">leaderboard</a>! </p>

    <asp:Label ID="lblEmpty" runat="server" Visible="false"
      Text="You haven't taken any quizzes yet. " CssClass="d-block" />
    <asp:HyperLink ID="lnkTakeQuiz" runat="server" Visible="false"
      CssClass="btn hq-btn btn-sm" NavigateUrl="~/Quiz/List" Text=" Take your first quiz" />

    <asp:PlaceHolder ID="phStats" runat="server" Visible="false">
      <div class="row text-center my-3">
        <div class="col-4">
          <div class="hq-stat">
            <div class="h3 mb-0"><asp:Literal ID="litQuizzes" runat="server" /></div>
            <small>Quizzes taken</small>
          </div>
        </div>
        <div class="col-4">
          <div class="hq-stat">
            <div class="h3 mb-0"><asp:Literal ID="litBest" runat="server" /></div>
            <small>Best score</small>
          </div>
        </div>
        <div class="col-4">
          <div class="hq-stat">
            <div class="h3 mb-0"><asp:Literal ID="litTotal" runat="server" /></div>
            <small>Total points</small>
          </div>
        </div>
      </div>

      <table class="table align-middle">
        <thead>
          <tr><th>Quiz</th><th class="text-end">Points</th><th>When</th></tr>
        </thead>
        <tbody>
          <asp:Repeater ID="rptScores" runat="server">
            <ItemTemplate>
              <tr>
                <td><%# Server.HtmlEncode((string)Eval("QuizTitle")) %></td>
                <td class="text-end fw-bold"><%# Eval("Points") %></td>
                <td><%# ((System.DateTime)Eval("TakenAt")).ToString("d MMM yyyy, h:mm tt") %></td>
              </tr>
            </ItemTemplate>
          </asp:Repeater>
        </tbody>
      </table>
    </asp:PlaceHolder>
  </div>
</asp:Content>
