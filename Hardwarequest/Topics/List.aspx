<%@ Page Title="Topics" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="List.aspx.cs" Inherits="Hardwarequest.Topics.List" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card">
    <h2 class="hq-title">Topics</h2>
    <p>Pick a topic and learn how computers work, one piece at a time.</p>

    <asp:Label ID="lblEmpty" runat="server" Visible="false"
      Text="No topics here yet. Check back soon!" CssClass="d-block" />

    <asp:Repeater ID="rptTopics" runat="server">
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
            <h3 class="h5 mb-2"><%# Server.HtmlEncode((string)Eval("Title")) %></h3>
            <p class="text-muted small mb-3"><%# Server.HtmlEncode(Snippet(Eval("Body"))) %></p>
            <div class="mt-auto">
              <a class="btn hq-btn btn-sm w-100"
                href='<%# ResolveUrl("~/Topics/Details?id=" + Eval("TopicId")) %>'>Read</a>
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
