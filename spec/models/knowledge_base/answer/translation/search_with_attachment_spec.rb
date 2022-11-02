# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/checks_kb_client_notification_examples'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Answer::Translation, type: :model, current_user_id: 1, searchindex: 1 do
  include_context 'basic Knowledge Base'

  let(:user)     { create(:admin) }
  let(:filename) { 'test.rtf' }
  let(:query)    { 'RTF document' }

  context 'search with attachment' do
    before do
      configure_elasticsearch(required: true, rebuild: true) do
        published_answer.add_attachment File.open "spec/fixtures/files/upload/#{filename}"
      end
    end

    it do
      expect(described_class.search(query: query, current_user: user))
        .to include published_answer.translations.first
    end

    # https://github.com/zammad/zammad/issues/4134
    context 'when associations are updated' do
      it 'does not delete the attachment from the search index' do
        User.find(1).search_index_update_associations
        SearchIndexBackend.refresh

        expect(described_class.search(query: query, current_user: user))
          .to include published_answer.translations.first
      end
    end
  end
end
