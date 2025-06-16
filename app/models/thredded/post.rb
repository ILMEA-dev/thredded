# frozen_string_literal: true

module Thredded
  class Post < ActiveRecord::Base
    include Thredded::PostCommon
    include Thredded::ContentModerationState

    belongs_to :user,
               class_name: Thredded.user_class_name,
               inverse_of: :thredded_posts,
               optional: true
    belongs_to :messageboard,
               counter_cache: true,
               inverse_of: :posts
    belongs_to :postable,
               class_name:    'Thredded::Topic',
               inverse_of:    :posts,
               counter_cache: true
    belongs_to :user_detail,
               inverse_of:    :posts,
               primary_key:   :user_id,
               foreign_key:   :user_id,
               counter_cache: true,
               optional: true
    belongs_to :parent,
               class_name: 'Thredded::Post',
               optional: true
    has_many :replies,
             class_name: 'Thredded::Post',
             foreign_key: :parent_id,
             dependent: :destroy,
             inverse_of: :parent
    has_many :moderation_records,
             class_name: 'Thredded::PostModerationRecord',
             dependent: :nullify
    has_many :user_notifications,
             class_name: 'Thredded::UserPostNotification',
             dependent: :destroy
    has_one :last_moderation_record, # rubocop:disable Rails/InverseOf
            -> { order_newest_first },
            class_name: 'Thredded::PostModerationRecord'

    validates :messageboard_id, presence: true
    validate :parent_belongs_to_same_topic, if: :parent_id?

    after_commit :update_parent_last_user_and_time_from_last_post, on: %i[create destroy]
    after_commit :update_parent_last_user_and_time_from_last_post_if_moderation_state_changed, on: :update

    after_commit :update_unread_posts_count_if_moderation_state_changed, on: :update

    after_commit :auto_follow_and_notify, on: %i[create update]

    # Finds the post by its ID, or raises {Thredded::Errors::PostNotFound}.
    # @param id [String, Number]
    # @return [Thredded::Post]
    # @raise [Thredded::Errors::PostNotFound] if the post with the given ID does not exist.
    def self.find!(id)
      find_by(id: id) || fail(Thredded::Errors::PostNotFound)
    end

    # @param [Integer] per_page
    # @param [Thredded.user_class] user
    def page(per_page: self.class.default_per_page, user:)
      readable_posts = PostPolicy::Scope.new(user, postable.posts).resolve
      calculate_page(readable_posts, per_page)
    end

    def private_topic_post?
      false
    end

    # @return [ActiveRecord::Relation<Thredded.user_class>] users that can read this post.
    def readers
      Thredded.user_class.thredded_messageboards_readers([messageboard])
    end

    def parent_id?
      parent_id.present?
    end

    private

    def parent_belongs_to_same_topic
      return unless parent && postable
      unless parent.postable_id == postable_id
        errors.add(:parent_id, 'must belong to the same topic')
      end
    end

    def auto_follow_and_notify
      return unless user
      # need to do this in-process so that it appears to them immediately
      if first_post_in_topic? ? Thredded.auto_follow_when_creating_topic : Thredded.auto_follow_when_posting_in_topic
        UserTopicFollow.create_unless_exists(user.id, postable_id, :posted)
      end
      # everything else can happen later
      AutoFollowAndNotifyJob.perform_later(id)
    end

    def update_parent_last_user_and_time_from_last_post
      return if destroyed_by_association
      postable.update_last_user_and_time_from_last_post!
      messageboard.update_last_topic!
    end

    def update_parent_last_user_and_time_from_last_post_if_moderation_state_changed
      update_parent_last_user_and_time_from_last_post if previous_changes.include?('moderation_state')
    end

    def update_unread_posts_count_if_moderation_state_changed
      update_unread_posts_count if previous_changes.include?('moderation_state')
    end
  end
end
