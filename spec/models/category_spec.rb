require 'rails_helper'

RSpec.describe Category, type: :model do
  subject { build(:category) }

  # Associations
  it { is_expected.to have_many(:ebooks) }

  # Validations
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to validate_uniqueness_of(:slug) }

  it "requires a slug to be present after the before_validation hook cannot fill it in" do
    category = Category.new(name: nil, slug: nil)
    expect(category).not_to be_valid
    expect(category.errors[:slug]).to include("can't be blank")
  end

  describe "slug auto-generation" do
    it "generates a slug from the name before validation" do
      category = build(:category, name: "Sacred Geometry", slug: nil)
      category.valid?
      expect(category.slug).to eq("sacred-geometry")
    end

    it "does not overwrite a manually set slug" do
      category = build(:category, name: "Sacred Geometry", slug: "custom-slug")
      category.valid?
      expect(category.slug).to eq("custom-slug")
    end
  end

  describe "dependent ebooks restriction" do
    it "cannot be deleted when it has ebooks" do
      category = create(:category)
      create(:ebook, category: category)
      expect { category.destroy }.not_to change(Category, :count)
    end

    it "adds an error on the model when deletion is blocked" do
      category = create(:category)
      create(:ebook, category: category)
      category.destroy
      expect(category.errors).not_to be_empty
    end
  end
end
