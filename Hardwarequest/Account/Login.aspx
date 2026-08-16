<%@ Page Title="Login" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="Hardwarequest.Account.Login" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card mx-auto" style="max-width:420px;">
    <h2 class="hq-title">Welcome back! </h2>
    <asp:Label ID="lblError" runat="server" CssClass="text-danger d-block mb-2" />
    <div class="mb-3">
      <label class="form-label">Username</label>
      <asp:TextBox ID="txtUsername" runat="server" CssClass="form-control" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtUsername"
        CssClass="text-danger" ErrorMessage="Username is required" Display="Dynamic" />
    </div>
    <div class="mb-3">
      <label class="form-label">Password</label>
      <asp:TextBox ID="txtPassword" runat="server" CssClass="form-control" TextMode="Password" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtPassword"
        CssClass="text-danger" ErrorMessage="Password is required" Display="Dynamic" />
    </div>
    <asp:Button ID="btnLogin" runat="server" Text="Log in" CssClass="btn hq-btn" OnClick="btnLogin_Click" />
    <p class="mt-3">New here? <a href="<%= ResolveUrl("~/Account/Register") %>">Create an account</a></p>
  </div>
</asp:Content>
