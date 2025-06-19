# frozen_string_literal: true

module Thredded
  class PostForm
    attr_reader :post, :topic, :parent_post
    delegate :id,
             :persisted?,
             :content,
             :content=,
             to: :@post

    # @param user [Thredded.user_class]
    # @param topic [Topic]
    # @param post [Post]
    # @param post_params [Hash]
    # @param parent_post [Post] optional parent post for replies
    def initialize(user:, topic:, post: nil, post_params: {}, parent_post: nil)
      @messageboard = topic.messageboard
      @topic = topic
      @parent_post = parent_post
      @post = post || topic.posts.build
      user ||= Thredded::NullUser.new

      if post_params.include?(:quote_post)
        post_params[:content] =
          Thredded::ContentFormatter.quote_content(post_params.delete(:quote_post).content)
      end
      
      # Set the parent first to ensure it's not overridden
      @post.parent = @parent_post if @parent_post
      
      @post.attributes = post_params.merge(
        user: (user unless user.thredded_anonymous?),
        messageboard: topic.messageboard
      )
    end

    def self.for_persisted(post)
      new(user: post.user, topic: post.postable, post: post)
    end

    def submit_path
      if @parent_post
        Thredded::UrlsHelper.messageboard_topic_posts_path(@messageboard, @topic)
      else
        Thredded::UrlsHelper.messageboard_topic_posts_path(@messageboard, @topic)
      end
    end

    def preview_path
      if @post.persisted?
        Thredded::UrlsHelper.messageboard_topic_post_preview_path(@messageboard, @topic, @post)
      else
        Thredded::UrlsHelper.preview_new_messageboard_topic_post_path(@messageboard, @topic)
      end
    end

    def save
      return false unless @post.valid?
      was_persisted = @post.persisted?
      @post.save!
      Thredded::UserTopicReadState.touch!(@post.user.id, @post) unless was_persisted
      true
    end

    def reply?
      @parent_post.present?
    end
  end
end
