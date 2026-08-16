<%@ Page Title="Quizzes" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="List.aspx.cs" Inherits="Hardwarequest.Quiz.List" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card">
    <h2 class="hq-title">Quizzes </h2>
    <p>Pick a quiz and test what you know! Earn more points on harder quizzes. </p>

    <div class="row align-items-end mb-3">
      <div class="col-auto">
        <label class="form-label mb-0">Show difficulty</label>
        <asp:DropDownList ID="ddlDifficulty" runat="server" CssClass="form-select"
          AutoPostBack="true" OnSelectedIndexChanged="ddlDifficulty_SelectedIndexChanged">
          <asp:ListItem Value="" Text="All levels" />
          <asp:ListItem Value="Easy" Text="Easy" />
          <asp:ListItem Value="Medium" Text="Medium" />
          <asp:ListItem Value="Hard" Text="Hard" />
        </asp:DropDownList>
      </div>
      <div class="col-auto">
        <a class="btn btn-warning" href="<%= ResolveUrl("~/Quiz/Leaderboard") %>">Leaderboard</a>
      </div>
    </div>

    <asp:Label ID="lblEmpty" runat="server" Visible="false"
      Text="No quizzes here yet. Check back soon! " CssClass="d-block" />

    <asp:Repeater ID="rptQuizzes" runat="server">
      <HeaderTemplate>
        <div class="row row-cols-1 row-cols-md-2 row-cols-lg-3 g-3">
      </HeaderTemplate>
      <ItemTemplate>
        <div class="col">
          <div class="card h-100 m-0 d-flex flex-column">
            <div class="text-center mb-2">
              <asp:Image runat="server" CssClass="img-fluid rounded" style="max-height:140px;"
                ImageUrl='<%# GetImage(Eval("ImagePath")) %>' AlternateText='<%# Eval("Title") %>' />
            </div>
            <div class="d-flex justify-content-between align-items-start mb-2">
              <h3 class="h5 mb-0"><%# Server.HtmlEncode((string)Eval("Title")) %></h3>
              <span class='badge <%# BadgeClass(Eval("Difficulty")) %>'><%# Server.HtmlEncode((string)Eval("Difficulty")) %></span>
            </div>
            <asp:PlaceHolder runat="server" Visible='<%# HasText(Eval("Description")) %>'>
              <p class="mb-2"><%# Server.HtmlEncode(Eval("Description") as string) %></p>
            </asp:PlaceHolder>
            <ul class="list-unstyled text-muted small mb-3">
              <li><strong><%# Eval("QuestionCount") %></strong> question(s)</li>
              <li><strong><%# Weight(Eval("Difficulty")) %></strong> point(s) per correct answer</li>
              <li>Worth up to <strong><%# MaxPoints(Eval("QuestionCount"), Eval("Difficulty")) %></strong> points</li>
            </ul>
            <div class="mt-auto">
              <a class="btn hq-btn btn-sm w-100"
                href='<%# ResolveUrl("~/Quiz/Take?id=" + Eval("QuizId")) %>'><%# TakeLabel %></a>
              <a class="btn btn-outline-warning btn-sm w-100 mt-2"
                href='<%# ResolveUrl("~/Quiz/Leaderboard?quizId=" + Eval("QuizId")) %>'>Leaderboard</a>
            </div>
          </div>
        </div>
      </ItemTemplate>
      <FooterTemplate>
        </div>
      </FooterTemplate>
    </asp:Repeater>
  </div>
</asp:Content>
