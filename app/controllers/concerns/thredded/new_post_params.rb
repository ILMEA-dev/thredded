# frozen_string_literal: true

module Thredded
  # @api private
  module NewPostParams
    protected

    def new_post_params
      params.fetch(:post, {})
        .permit(:content, :quote_post_id, :parent_id)
        .tap do |p|
        quote_id = p.delete(:quote_post_id)
        if quote_id
          post = Thredded::Post.find(quote_id)
          authorize_reading post
          p[:quote_post] = post
        end

        parent_id = p.delete(:parent_id)
        if parent_id.present?
          post = Thredded::Post.find(parent_id)
          authorize_reading post
          p[:parent] = post
        end
      end
    end
  end
end
