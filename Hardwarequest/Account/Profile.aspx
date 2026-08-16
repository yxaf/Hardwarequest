<%@ Page Title="My Profile" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Profile.aspx.cs" Inherits="Hardwarequest.Account.UserProfile" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card mx-auto" style="max-width:520px;">
    <h2 class="hq-title">My Profile</h2>
    <p class="text-muted">
      Signed in as <strong><asp:Literal ID="litUsername" runat="server" /></strong>
      (<asp:Literal ID="litRole" runat="server" />)
    </p>

    <h3 class="h5 mt-4">My details</h3>
    <asp:Label ID="lblDetailsMsg" runat="server" CssClass="d-block mb-2" />
    <div class="mb-3">
      <label class="form-label">Full name</label>
      <asp:TextBox ID="txtFullName" runat="server" CssClass="form-control" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtFullName" ValidationGroup="details"
        CssClass="text-danger" ErrorMessage="Full name is required" Display="Dynamic" />
    </div>
    <div class="mb-3">
      <label class="form-label">Email</label>
      <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control" TextMode="Email" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtEmail" ValidationGroup="details"
        CssClass="text-danger" ErrorMessage="Email is required" Display="Dynamic" />
      <asp:RegularExpressionValidator runat="server" ControlToValidate="txtEmail" ValidationGroup="details"
        CssClass="text-danger" Display="Dynamic"
        ValidationExpression="^[^@\s]+@[^@\s]+\.[^@\s]+$" ErrorMessage="Enter a valid email" />
    </div>
    <asp:Button ID="btnSaveDetails" runat="server" Text="Save changes" CssClass="btn hq-btn"
      ValidationGroup="details" OnClick="btnSaveDetails_Click" />

    <hr class="my-4" />

    <h3 class="h5">Change password</h3>
    <asp:Label ID="lblPasswordMsg" runat="server" CssClass="d-block mb-2" />
    <div class="mb-3">
      <label class="form-label">Current password</label>
      <asp:TextBox ID="txtCurrent" runat="server" CssClass="form-control" TextMode="Password" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtCurrent" ValidationGroup="password"
        CssClass="text-danger" ErrorMessage="Current password is required" Display="Dynamic" />
    </div>
    <div class="mb-3">
      <label class="form-label">New password</label>
      <asp:TextBox ID="txtNew" runat="server" CssClass="form-control" TextMode="Password" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtNew" ValidationGroup="password"
        CssClass="text-danger" ErrorMessage="New password is required" Display="Dynamic" />
      <asp:RegularExpressionValidator runat="server" ControlToValidate="txtNew" ValidationGroup="password"
        CssClass="text-danger" Display="Dynamic"
        ValidationExpression="^.{6,}$" ErrorMessage="At least 6 characters" />
    </div>
    <div class="mb-3">
      <label class="form-label">Confirm new password</label>
      <asp:TextBox ID="txtConfirmNew" runat="server" CssClass="form-control" TextMode="Password" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtConfirmNew" ValidationGroup="password"
        CssClass="text-danger" ErrorMessage="Please confirm the new password" Display="Dynamic" />
      <asp:CompareValidator runat="server" ControlToValidate="txtConfirmNew" ControlToCompare="txtNew"
        ValidationGroup="password" CssClass="text-danger" Display="Dynamic"
        ErrorMessage="Passwords do not match" />
    </div>
    <asp:Button ID="btnChangePassword" runat="server" Text="Change password" CssClass="btn hq-btn"
      ValidationGroup="password" OnClick="btnChangePassword_Click" />
  </div>
</asp:Content>
