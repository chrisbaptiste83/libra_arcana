require 'rails_helper'

RSpec.describe "Ebooks", type: :request do
  let!(:category) { create(:category) }
  let!(:ebook)    { create(:ebook, category: category) }

  describe "GET /ebooks" do
    it "returns http success" do
      get ebooks_path
      expect(response).to have_http_status(:success)
    end

    it "displays ebooks" do
      get ebooks_path
      expect(response.body).to include(ebook.title)
    end

    it "filters by search query" do
      other = create(:ebook, title: "Unique Title XYZZY", category: category)
      get ebooks_path, params: { search: "XYZZY" }
      expect(response.body).to include(other.title)
      expect(response.body).not_to include(ebook.title)
    end

    it "filters by category" do
      other_cat   = create(:category)
      other_ebook = create(:ebook, category: other_cat)
      get ebooks_path, params: { category_id: category.id }
      expect(response.body).to include(ebook.title)
      expect(response.body).not_to include(other_ebook.title)
    end
  end

  describe "GET /ebooks/:id" do
    it "returns http success" do
      get ebook_path(ebook)
      expect(response).to have_http_status(:success)
    end

    it "displays the ebook title" do
      get ebook_path(ebook)
      expect(response.body).to include(ebook.title)
    end

    it "displays the ebook author" do
      get ebook_path(ebook)
      expect(response.body).to include(ebook.author)
    end
  end
end
