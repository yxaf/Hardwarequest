<%@ Page Title="Add Topic" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Create.aspx.cs" Inherits="Hardwarequest.Topics.Create" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card mx-auto" style="max-width:900px;">
    <h2 class="hq-title">Add a topic</h2>
    <asp:Label ID="lblError" runat="server" CssClass="text-danger d-block mb-2" />

    <div class="mb-3">
      <label class="form-label">Title</label>
      <asp:TextBox ID="txtTitle" runat="server" CssClass="form-control" placeholder="e.g. How a CPU works" />
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
      <label class="form-label">Cover picture <span class="text-muted">(PNG, JPG or GIF, optional)</span></label>
      <div class="d-flex align-items-start gap-3">
        <div class="flex-grow-1">
          <asp:FileUpload ID="fileImage" runat="server" CssClass="form-control" data-preview="topicImgPrev" />
        </div>
        <img id="topicImgPrev" class="rounded" style="display:none;max-height:96px;" alt="Cover picture preview" />
      </div>
    </div>

    <asp:Button ID="btnSave" runat="server" Text="Save topic" CssClass="btn hq-btn" OnClick="btnSave_Click" />
    <a class="btn btn-link" href="<%= ResolveUrl("~/Topics/List") %>">Cancel</a>
  </div>
</asp:Content>
