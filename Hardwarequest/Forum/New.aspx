<%@ Page Title="Start a Discussion" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="New.aspx.cs" Inherits="Hardwarequest.Forum.New" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card mx-auto" style="max-width:900px;">
    <h2 class="hq-title">Start a discussion </h2>
    <div class="mb-3">
      <label class="form-label">Title</label>
      <asp:TextBox ID="txtTitle" runat="server" CssClass="form-control" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtTitle"
        CssClass="text-danger" Display="Dynamic" ErrorMessage="A title is required" />
    </div>
    <div class="mb-3">
      <label class="form-label">Your message</label>
      <asp:TextBox ID="txtBody" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="10" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtBody"
        CssClass="text-danger" Display="Dynamic" ErrorMessage="Please write your message" />
    </div>
    <asp:Button ID="btnPost" runat="server" Text="Post discussion" CssClass="btn hq-btn" OnClick="btnPost_Click" />
    <a class="btn btn-link" href="<%= ResolveUrl("~/Forum/List") %>">Cancel</a>
  </div>
</asp:Content>
