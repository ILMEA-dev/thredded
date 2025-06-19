# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'thredded/posts/new', type: :view do
  let(:user) { create(:user) }
  let(:messageboard) { create(:messageboard) }
  let(:topic) { create(:topic, messageboard: messageboard) }
  let(:parent_post) { create(:post, postable: topic, user: user, content: 'parent post') }
  let(:post_form) do
    Thredded::PostForm.new(
      user: user,
      topic: topic,
      parent_post: parent_post,
      post_params: { content: 'reply content' }
    )
  end

  before do
    allow(view).to receive(:thredded_current_user).and_return(user)
    allow(view).to receive(:messageboard_or_nil).and_return(messageboard)
    allow(view).to receive(:autocomplete_users_path).and_return('/autocomplete-users')
    allow(view).to receive(:t).and_return('translated text')
    assign(:post_form, post_form)
    assign(:messageboard, messageboard)
  end

  it 'renders the hidden parent_id field when replying' do
    render
    expect(rendered).to have_field('post[parent_id]', type: 'hidden', with: parent_post.id.to_s)
  end

  it 'renders the form with the correct action' do
    render
    expect(rendered).to have_selector('form[action*="posts"]')
  end
end 