require 'rails_helper'

RSpec.describe "Favorites", type: :request do
  let(:user)  { create(:user) }
  let(:ebook) { create(:ebook) }

  describe "POST /favorites" do
    context "when not signed in" do
      it "redirects to sign in" do
        post favorites_path, params: { ebook_id: ebook.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "creates a favorite and redirects back" do
        expect {
          post favorites_path, params: { ebook_id: ebook.id }
        }.to change(Favorite, :count).by(1)
      end

      it "does not create a duplicate favorite" do
        create(:favorite, user: user, ebook: ebook)
        expect {
          post favorites_path, params: { ebook_id: ebook.id }
        }.not_to change(Favorite, :count)
      end
    end
  end

  describe "DELETE /favorites/:id" do
    context "when not signed in" do
      it "redirects to sign in" do
        favorite = create(:favorite, user: user, ebook: ebook)
        delete favorite_path(favorite)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "destroys the favorite" do
        favorite = create(:favorite, user: user, ebook: ebook)
        expect {
          delete favorite_path(favorite)
        }.to change(Favorite, :count).by(-1)
      end

      it "cannot destroy another user's favorite" do
        other_user = create(:user)
        favorite   = create(:favorite, user: other_user, ebook: ebook)
        expect { delete favorite_path(favorite) }.not_to change(Favorite, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
