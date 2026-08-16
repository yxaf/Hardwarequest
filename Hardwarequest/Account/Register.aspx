<%@ Page Title="Register" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Register.aspx.cs" Inherits="Hardwarequest.Account.Register" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card mx-auto" style="max-width:480px;">
    <h2 class="hq-title">Create your account </h2>
    <asp:Label ID="lblError" runat="server" CssClass="text-danger d-block mb-2" />

    <div class="mb-3">
      <label class="form-label">Full name</label>
      <asp:TextBox ID="txtFullName" runat="server" CssClass="form-control" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtFullName"
        CssClass="text-danger" ErrorMessage="Full name is required" Display="Dynamic" />
    </div>
    <div class="mb-3">
      <label class="form-label">Username</label>
      <asp:TextBox ID="txtUsername" runat="server" CssClass="form-control" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtUsername"
        CssClass="text-danger" ErrorMessage="Username is required" Display="Dynamic" />
    </div>
    <div class="mb-3">
      <label class="form-label">Email</label>
      <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control" TextMode="Email" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtEmail"
        CssClass="text-danger" ErrorMessage="Email is required" Display="Dynamic" />
      <asp:RegularExpressionValidator runat="server" ControlToValidate="txtEmail"
        CssClass="text-danger" Display="Dynamic"
        ValidationExpression="^[^@\s]+@[^@\s]+\.[^@\s]+$" ErrorMessage="Enter a valid email" />
    </div>
    <div class="mb-3">
      <label class="form-label">Password</label>
      <asp:TextBox ID="txtPassword" runat="server" CssClass="form-control" TextMode="Password" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtPassword"
        CssClass="text-danger" ErrorMessage="Password is required" Display="Dynamic" />
      <asp:RegularExpressionValidator runat="server" ControlToValidate="txtPassword"
        CssClass="text-danger" Display="Dynamic"
        ValidationExpression="^.{6,}$" ErrorMessage="At least 6 characters" />
    </div>
    <div class="mb-3">
      <label class="form-label">I am a</label>
      <asp:DropDownList ID="ddlRole" runat="server" CssClass="form-select">
        <asp:ListItem Value="Student" Text="Student" />
        <asp:ListItem Value="Lecturer" Text="Lecturer" />
      </asp:DropDownList>
    </div>
    <div class="mb-3">
      <label class="form-label">Confirm password</label>
      <asp:TextBox ID="txtConfirm" runat="server" CssClass="form-control" TextMode="Password" />
      <asp:CompareValidator runat="server" ControlToValidate="txtConfirm"
        ControlToCompare="txtPassword" CssClass="text-danger" Display="Dynamic"
        ErrorMessage="Passwords do not match" />
    </div>

    <asp:Button ID="btnRegister" runat="server" Text="Sign up" CssClass="btn hq-btn"
      OnClick="btnRegister_Click" />
    <p class="mt-3">Already have an account? <a href="<%= ResolveUrl("~/Account/Login") %>">Log in</a></p>
  </div>
</asp:Content>
