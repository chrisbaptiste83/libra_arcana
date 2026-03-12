require 'rails_helper'

RSpec.describe ReadingListItem, type: :model do
  subject { build(:reading_list_item) }

  # Associations
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:ebook) }

  # Validations
  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to validate_inclusion_of(:status).in_array(ReadingListItem::STATUSES) }

  describe "uniqueness per user/ebook pair" do
    let(:user)  { create(:user) }
    let(:ebook) { create(:ebook) }

    it "prevents duplicate entries" do
      create(:reading_list_item, user: user, ebook: ebook)
      duplicate = build(:reading_list_item, user: user, ebook: ebook)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:ebook_id]).to include("already on your reading list")
    end
  end

  describe "STATUSES constant" do
    it "includes the three expected statuses" do
      expect(ReadingListItem::STATUSES).to contain_exactly(
        "want_to_read", "currently_reading", "completed"
      )
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:want)      { create(:reading_list_item, user: user, status: "want_to_read") }
    let!(:reading)   { create(:reading_list_item, :currently_reading, user: user) }
    let!(:completed) { create(:reading_list_item, :completed, user: user) }

    it ".want_to_read returns only want_to_read items" do
      expect(ReadingListItem.want_to_read).to include(want)
      expect(ReadingListItem.want_to_read).not_to include(reading, completed)
    end

    it ".currently_reading returns only currently_reading items" do
      expect(ReadingListItem.currently_reading).to include(reading)
      expect(ReadingListItem.currently_reading).not_to include(want, completed)
    end

    it ".completed returns only completed items" do
      expect(ReadingListItem.completed).to include(completed)
      expect(ReadingListItem.completed).not_to include(want, reading)
    end
  end

  describe "#status_label" do
    it "humanizes want_to_read" do
      item = build(:reading_list_item, status: "want_to_read")
      expect(item.status_label).to eq("Want to read")
    end

    it "humanizes currently_reading" do
      item = build(:reading_list_item, status: "currently_reading")
      expect(item.status_label).to eq("Currently reading")
    end

    it "humanizes completed" do
      item = build(:reading_list_item, status: "completed")
      expect(item.status_label).to eq("Completed")
    end
  end
end
