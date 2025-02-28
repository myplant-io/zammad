# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Relation
  attr_reader :context, :current_user, :data, :filter_ids

  def initialize(context:, current_user:, data: {}, filter_ids: [])
    @context = context
    @current_user = current_user
    @data = data
    @filter_ids = filter_ids
  end

  def options
    options = []

    items.each do |item|
      options.push({ value: item.id, label: display_name(item) })
    end

    options
  end

  private

  def order
    { id: :asc }
  end

  def display_name(item)
    item.name
  end

  def relation_type
    raise NotImplementedError
  end

  def items
    @items ||= begin
      if filter_ids
        relation_type.where(id: filter_ids).order(order)
      else
        # TODO: correct fallback for later in the admin interface.
        # relation_type.where(active: true).order(id: :asc)
        []
      end
    end
  end
end
