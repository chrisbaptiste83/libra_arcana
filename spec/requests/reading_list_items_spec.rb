require 'rails_helper'

RSpec.describe "ReadingListItems", type: :request do
  let(:user)  { create(:user) }
  let(:ebook) { create(:ebook) }

  describe "POST /reading_list_items" do
    context "when not signed in" do
      it "redirects to sign in" do
        post reading_list_items_path, params: { ebook_id: ebook.id, status: "want_to_read" }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "creates a reading list item with the given status" do
        expect {
          post reading_list_items_path, params: { ebook_id: ebook.id, status: "currently_reading" }
        }.to change(ReadingListItem, :count).by(1)

        expect(ReadingListItem.last.status).to eq("currently_reading")
      end

      it "defaults to want_to_read when no status is given" do
        post reading_list_items_path, params: { ebook_id: ebook.id }
        expect(ReadingListItem.last.status).to eq("want_to_read")
      end

      it "does not create a duplicate entry for the same ebook" do
        create(:reading_list_item, user: user, ebook: ebook)
        expect {
          post reading_list_items_path, params: { ebook_id: ebook.id, status: "completed" }
        }.not_to change(ReadingListItem, :count)
      end
    end
  end

  describe "PATCH /reading_list_items/:id" do
    context "when signed in" do
      before { sign_in user }

      it "updates the status" do
        item = create(:reading_list_item, user: user, ebook: ebook, status: "want_to_read")
        patch reading_list_item_path(item),
              params: { reading_list_item: { status: "completed" } }
        expect(item.reload.status).to eq("completed")
      end

      it "cannot update another user's item" do
        other = create(:user)
        item  = create(:reading_list_item, user: other, ebook: ebook)
        patch reading_list_item_path(item),
              params: { reading_list_item: { status: "completed" } }
        expect(response).to have_http_status(:not_found)
        expect(item.reload.status).not_to eq("completed")
      end
    end
  end

  describe "DELETE /reading_list_items/:id" do
    context "when signed in" do
      before { sign_in user }

      it "removes the item from the reading list" do
        item = create(:reading_list_item, user: user, ebook: ebook)
        expect {
          delete reading_list_item_path(item)
        }.to change(ReadingListItem, :count).by(-1)
      end
    end
  end
end
