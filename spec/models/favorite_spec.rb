require 'rails_helper'

RSpec.describe Favorite, type: :model do
  subject { build(:favorite) }

  # Associations
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:ebook) }

  describe "uniqueness per user/ebook pair" do
    let(:user)  { create(:user) }
    let(:ebook) { create(:ebook) }

    it "allows one favorite per user per ebook" do
      create(:favorite, user: user, ebook: ebook)
      duplicate = build(:favorite, user: user, ebook: ebook)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:ebook_id]).to include("already in your favorites")
    end

    it "allows different users to favorite the same ebook" do
      user2 = create(:user)
      create(:favorite, user: user, ebook: ebook)
      expect(build(:favorite, user: user2, ebook: ebook)).to be_valid
    end

    it "allows one user to favorite different ebooks" do
      ebook2 = create(:ebook)
      create(:favorite, user: user, ebook: ebook)
      expect(build(:favorite, user: user, ebook: ebook2)).to be_valid
    end
  end
end
