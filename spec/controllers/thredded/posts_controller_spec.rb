# frozen_string_literal: true

require 'spec_helper'

module Thredded
  describe PostsController do
    routes { Thredded::Engine.routes }

    let(:user) { create(:user) }
    let(:messageboard) { create(:messageboard) }
    let(:topic) { create(:topic, messageboard: messageboard, title: 'hi') }
    let(:the_post) { create(:post, postable: topic, content: 'hi') }

    before do
      allow(controller).to receive_messages(
        the_current_user: user,
      )
    end

    describe 'POST mark_as_read' do
      subject(:do_post_request) { post :mark_as_read, params: { id: the_post.id } }

      it 'marks as read' do
        expect(UserTopicReadState).to receive(:touch!).with(user.id, the_post)
        do_post_request
      end

      it 'sets the messageboard correctly' do
        do_post_request
        expect(assigns(:messageboard)).to eq(messageboard)
      end

      context 'json format' do
        subject(:do_post_request) do
          post :mark_as_read, params: { id: the_post.id, format: :json }
        end

        it 'returns changed status' do
          expect(UserTopicReadState).to receive(:touch!).with(user.id, the_post)
          do_post_request
          expect(JSON.parse(response.body)).to include('read' => true)
        end
      end
    end

    describe 'POST mark_as_unread' do
      subject(:do_post_request) do
        post :mark_as_unread, params: { id: the_post.id }
      end

      it 'marks as unread' do
        UserTopicReadState.touch!(user.id, the_post)
        expect { do_post_request }.to change(UserTopicReadState, :count).by(-1)
      end

      it 'sets the messageboard correctly' do
        do_post_request
        expect(assigns(:messageboard)).to eq(messageboard)
      end

      context 'json format' do
        subject(:do_post_request) do
          post :mark_as_unread, params: { id: the_post.id, format: :json }
        end

        it 'returns changed status' do
          do_post_request
          expect(JSON.parse(response.body)).to include('read' => false)
        end
      end
    end

    describe 'GET reply' do
      let!(:parent_post) { create(:post, postable: topic, content: 'parent') }
      it 'assigns a PostForm with the correct parent_id' do
        get :reply, params: { messageboard_id: messageboard.id, topic_id: topic.id, id: parent_post.id }
        post_form = assigns(:post_form)
        expect(post_form.parent_post).to eq(parent_post)
        expect(post_form.post.parent_id).to eq(parent_post.id)
      end
    end

    describe 'POST create' do
      let!(:parent_post) { create(:post, postable: topic, content: 'parent') }
      it 'creates a reply with the correct parent_id' do
        expect {
          post :create, params: {
            messageboard_id: messageboard.id,
            topic_id: topic.id,
            post: { content: 'reply content', parent_id: parent_post.id }
          }
        }.to change(Thredded::Post, :count).by(1)
        reply = Thredded::Post.order(:created_at).last
        expect(reply.parent_id).to eq(parent_post.id)
        expect(reply.parent).to eq(parent_post)
      end
    end
  end
end
