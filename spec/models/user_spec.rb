require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  # Associations
  it { is_expected.to have_many(:favorites).dependent(:destroy) }
  it { is_expected.to have_many(:favorited_ebooks).through(:favorites).source(:ebook) }
  it { is_expected.to have_many(:reading_list_items).dependent(:destroy) }
  it { is_expected.to have_many(:reading_list_ebooks).through(:reading_list_items).source(:ebook) }

  # Validations
  it { is_expected.to validate_presence_of(:first_name) }
  it { is_expected.to validate_presence_of(:last_name) }
  it { is_expected.to validate_presence_of(:email) }

  describe "#full_name" do
    it "returns the concatenated first and last name" do
      user = build(:user, first_name: "Aleister", last_name: "Crowley")
      expect(user.full_name).to eq("Aleister Crowley")
    end
  end

  describe "#favorited?" do
    let(:user)  { create(:user) }
    let(:ebook) { create(:ebook) }

    context "when the ebook is favorited" do
      before { create(:favorite, user: user, ebook: ebook) }

      it { expect(user.favorited?(ebook)).to be true }
    end

    context "when the ebook is not favorited" do
      it { expect(user.favorited?(ebook)).to be false }
    end
  end

  describe "#reading_list_item_for" do
    let(:user)  { create(:user) }
    let(:ebook) { create(:ebook) }

    context "when the ebook is on the reading list" do
      let!(:item) { create(:reading_list_item, user: user, ebook: ebook) }

      it "returns the reading list item" do
        expect(user.reading_list_item_for(ebook)).to eq(item)
      end
    end

    context "when the ebook is not on the reading list" do
      it "returns nil" do
        expect(user.reading_list_item_for(ebook)).to be_nil
      end
    end
  end

  describe "admin flag" do
    it "is false by default" do
      expect(create(:user).admin).to be false
    end

    it "can be set to true with the admin trait" do
      expect(create(:user, :admin).admin).to be true
    end
  end
end
