<%@ Page Title="Manage" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="Hardwarequest.Manage.Default" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card">
    <h2 class="hq-title">Manage</h2>
    <p>Manage the content you have created. <asp:Literal ID="litScope" runat="server" /></p>
    <div class="row row-cols-1 row-cols-md-3 g-3">
      <div class="col"><div class="card h-100 m-0 text-center p-3">
        <h3 class="h5">My Quizzes</h3>
        <p class="display-6 mb-1"><asp:Literal ID="litQuizzes" runat="server" /></p>
        <a class="btn hq-btn w-100" href='<%= ResolveUrl("~/Manage/Quizzes") %>'>Open</a>
      </div></div>
      <div class="col"><div class="card h-100 m-0 text-center p-3">
        <h3 class="h5">My Topics</h3>
        <p class="display-6 mb-1"><asp:Literal ID="litTopics" runat="server" /></p>
        <a class="btn hq-btn w-100" href='<%= ResolveUrl("~/Manage/Topics") %>'>Open</a>
      </div></div>
      <div class="col"><div class="card h-100 m-0 text-center p-3">
        <h3 class="h5">My Threads</h3>
        <p class="display-6 mb-1"><asp:Literal ID="litThreads" runat="server" /></p>
        <a class="btn hq-btn w-100"  href='<%= ResolveUrl("~/Manage/Threads") %>'>Open</a>
      </div></div>
    </div>
  </div>
</asp:Content>
