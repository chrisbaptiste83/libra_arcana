require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  describe "GET /profile" do
    context "when not signed in" do
      it "redirects to sign in" do
        get profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      let(:user)  { create(:user) }
      let(:ebook) { create(:ebook) }

      before { sign_in user }

      it "returns http success" do
        get profile_path
        expect(response).to have_http_status(:success)
      end

      it "shows the user's favorites" do
        create(:favorite, user: user, ebook: ebook)
        get profile_path
        expect(response.body).to include(ebook.title)
      end

      it "shows the user's reading list items" do
        create(:reading_list_item, user: user, ebook: ebook, status: "currently_reading")
        get profile_path
        expect(response.body).to include(ebook.title)
      end
    end
  end
end
