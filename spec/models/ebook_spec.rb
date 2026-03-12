require 'rails_helper'

RSpec.describe Ebook, type: :model do
  subject { build(:ebook) }

  # Associations
  it { is_expected.to belong_to(:category) }
  it { is_expected.to have_many(:favorites).dependent(:destroy) }
  it { is_expected.to have_many(:favorited_by_users).through(:favorites).source(:user) }
  it { is_expected.to have_many(:reading_list_items).dependent(:destroy) }

  # Validations
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:author) }
  it { is_expected.to validate_presence_of(:description) }

  describe ".featured scope" do
    let!(:featured) { create(:ebook, :featured) }
    let!(:regular)  { create(:ebook) }

    it "returns only featured ebooks" do
      expect(Ebook.featured).to include(featured)
      expect(Ebook.featured).not_to include(regular)
    end
  end

  describe ".search scope" do
    let!(:ebook) { create(:ebook, title: "The Book of the Law", author: "Crowley", description: "Thelema") }

    it "finds by title" do
      expect(Ebook.search("Book of the Law")).to include(ebook)
    end

    it "finds by author" do
      expect(Ebook.search("Crowley")).to include(ebook)
    end

    it "finds by description" do
      expect(Ebook.search("Thelema")).to include(ebook)
    end

    it "is case-insensitive" do
      expect(Ebook.search("book of the law")).to include(ebook)
    end

    it "returns all ebooks when query is blank" do
      expect(Ebook.search("")).to include(ebook)
    end
  end

  describe ".by_category scope" do
    let(:category_a) { create(:category) }
    let(:category_b) { create(:category) }
    let!(:ebook_a)   { create(:ebook, category: category_a) }
    let!(:ebook_b)   { create(:ebook, category: category_b) }

    it "filters to the given category" do
      expect(Ebook.by_category(category_a.id)).to include(ebook_a)
      expect(Ebook.by_category(category_a.id)).not_to include(ebook_b)
    end

    it "returns all ebooks when category_id is blank" do
      expect(Ebook.by_category("")).to include(ebook_a, ebook_b)
    end
  end
end
