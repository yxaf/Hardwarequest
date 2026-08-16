<%@ Page Title="Edit Topic" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Edit.aspx.cs" Inherits="Hardwarequest.Topics.Edit" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card mx-auto" style="max-width:900px;">
    <h2 class="hq-title">Edit topic</h2>
    <asp:Label ID="lblError" runat="server" CssClass="text-danger d-block mb-2" />

    <div class="mb-3">
      <label class="form-label">Title</label>
      <asp:TextBox ID="txtTitle" runat="server" CssClass="form-control" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtTitle"
        CssClass="text-danger" Display="Dynamic" ErrorMessage="Title is required" />
    </div>
    <div class="mb-3">
      <label class="form-label">Lesson content</label>
      <asp:TextBox ID="txtBody" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="10" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtBody"
        CssClass="text-danger" Display="Dynamic" ErrorMessage="Lesson content is required" />
    </div>
    <div class="mb-3">
      <label class="form-label">Current picture</label><br />
      <asp:Image ID="imgCurrent" runat="server" CssClass="img-fluid rounded mb-2" Style="max-width:160px;" />
    </div>
    <div class="mb-3">
      <label class="form-label">Replace picture <span class="text-muted">(leave empty to keep current)</span></label>
      <div class="d-flex align-items-start gap-3">
        <div class="flex-grow-1">
          <asp:FileUpload ID="fileImage" runat="server" CssClass="form-control" data-preview="topicImgPrev" />
        </div>
        <img id="topicImgPrev" class="rounded" style="display:none;max-height:96px;" alt="New picture preview" />
      </div>
    </div>

    <asp:Button ID="btnSave" runat="server" Text="Save changes" CssClass="btn hq-btn" OnClick="btnSave_Click" />
    <a class="btn btn-link" href="<%= ResolveUrl("~/Topics/List") %>">Cancel</a>
  </div>
</asp:Content>
