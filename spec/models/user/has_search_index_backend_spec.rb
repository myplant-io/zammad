# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'HasSearchIndexBackend', type: :model, searchindex: true do
  describe 'Updating referenced data between user and organizations' do
    let(:organization) { create(:organization, name: 'Tomato42') }
    let(:user)         { create(:customer, organization: organization) }

    before do
      configure_elasticsearch(required: true, rebuild: true) do
        user.search_index_update_backend
        organization.search_index_update_backend
      end
    end

    it 'finds added users' do
      result = SearchIndexBackend.search('organization.name:Tomato42', 'User', sort_by: ['updated_at'], order_by: ['desc'])
      expect(result).to eq([{ id: user.id.to_s, type: 'User' }])
    end

    context 'when renaming the organization' do
      before do
        organization.update(name: 'Cucumber43 Ltd.')
        organization.search_index_update_associations
        SearchIndexBackend.refresh
      end

      it 'finds added users by organization name in sub hash' do
        result = SearchIndexBackend.search('organization.name:Cucumber43', 'User', sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([{ id: user.id.to_s, type: 'User' }])
      end

      it 'finds added users by organization name' do
        result = SearchIndexBackend.search('Cucumber43', 'User', sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([{ id: user.id.to_s, type: 'User' }])
      end
    end

    it 'does include User for bulk action updates' do
      expect(organization).to be_search_index_indexable_bulk_updates(User)
    end
  end

  describe 'Updating group settings causes huge numbers of delayed jobs #4306' do
    let(:user) { create(:user) }

    before do
      configure_elasticsearch(required: true, rebuild: true) do
        user
        Delayed::Job.destroy_all
      end
    end

    it 'does not create any jobs if nothing has changed' do
      expect { user.update(firstname: user.firstname) }.not_to change(Delayed::Job, :count)
    end
  end
end
