# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Thredded::PostForm do
  let(:user) { create(:user) }
  let(:messageboard) { create(:messageboard) }
  let(:topic) { create(:topic, messageboard: messageboard) }
  let(:parent_post) { create(:post, postable: topic, user: user) }

  describe '#initialize' do
    context 'with parent_post' do
      it 'sets parent_id correctly' do
        post_form = described_class.new(
          user: user,
          topic: topic,
          parent_post: parent_post
        )
        
        expect(post_form.post.parent_id).to eq(parent_post.id)
      end

      it 'sets parent_id when passed in post_params' do
        post_form = described_class.new(
          user: user,
          topic: topic,
          post_params: { parent_id: parent_post.id }
        )
        
        expect(post_form.post.parent_id).to eq(parent_post.id)
      end
    end

    context 'without parent_post' do
      it 'does not set parent_id' do
        post_form = described_class.new(
          user: user,
          topic: topic
        )
        
        expect(post_form.post.parent_id).to be_nil
      end
    end
  end

  describe '#save' do
    it 'saves the post with parent_id when parent_post is provided' do
      post_form = described_class.new(
        user: user,
        topic: topic,
        parent_post: parent_post,
        post_params: { content: 'This is a reply' }
      )
      
      expect(post_form.save).to be true
      expect(post_form.post.parent_id).to eq(parent_post.id)
      expect(post_form.post.parent).to eq(parent_post)
    end
  end

  describe '#reply?' do
    it 'returns true when parent_post is present' do
      post_form = described_class.new(
        user: user,
        topic: topic,
        parent_post: parent_post
      )
      
      expect(post_form.reply?).to be true
    end

    it 'returns false when parent_post is not present' do
      post_form = described_class.new(
        user: user,
        topic: topic
      )
      
      expect(post_form.reply?).to be false
    end
  end
end 