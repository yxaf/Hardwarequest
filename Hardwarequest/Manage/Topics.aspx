<%@ Page Title="My Topics" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Topics.aspx.cs" Inherits="Hardwarequest.Manage.TopicsManage" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h2 class="hq-title mb-0">My Topics</h2>
      <a class="btn hq-btn" href='<%= ResolveUrl("~/Topics/Create") %>'>Create topic</a>
    </div>
    <asp:Label ID="lblEmpty" runat="server" Visible="false" CssClass="d-block"
      Text="You have not created any topics yet." />
    <asp:Repeater ID="rpt" runat="server" OnItemCommand="rpt_ItemCommand">
      <HeaderTemplate><div class="row row-cols-1 row-cols-md-2 g-3"></HeaderTemplate>
      <ItemTemplate>
        <div class="col"><div class="card h-100 m-0 p-3 d-flex flex-column">
          <h3 class="h5 mb-1"><%# Server.HtmlEncode((string)Eval("Title")) %></h3>
          <p class="text-muted small mb-2"><%# OwnerLabel(Eval("OwnerName")) %> &middot; created <%# ((System.DateTime)Eval("CreatedAt")).ToString("yyyy-MM-dd") %></p>
          <div class="mt-auto btn-group btn-group-sm w-100" role="group">
            <a class="btn btn-outline-primary" href='<%# ResolveUrl("~/Topics/Details?id=" + Eval("TopicId")) %>'>View</a>
            <a class="btn btn-outline-success" href='<%# ResolveUrl("~/Topics/Edit?id=" + Eval("TopicId")) %>'>Edit</a>
            <asp:Button runat="server" CssClass="btn btn-outline-danger" Text="Delete"
              CommandName="DeleteTopic" CommandArgument='<%# Eval("TopicId") %>'
              OnClientClick="return hqConfirm(this,'Delete this topic?');" />
          </div>
        </div></div>
      </ItemTemplate>
      <FooterTemplate></div></FooterTemplate>
    </asp:Repeater>
  </div>
</asp:Content>
