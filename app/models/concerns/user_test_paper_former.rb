module UserTestPaperFormer
  extend ActiveSupport::Concern

  included do

    former "UserTestPaper" do
      field :id, ->(instance) {instance.id.to_s}
      field :current_user, ->(instance) {
        {
          id:   instance.user_id.to_s,
          name: instance.user.name
        }
      }

      field :status, ->(instance) {
        tpr = instance.user.inspect_test_paper_result
        return "NOT_START" if tpr.blank?
        return "RUNNING"   if Time.now < tpr.created_at + instance.test_paper.minutes.minutes
        return "FINISHED"
      }

      field :deadline_time, ->(instance) {
        tpr = instance.user.inspect_test_paper_result
        return 0 if tpr.blank?
        time = tpr.created_at + instance.test_paper.minutes.minutes
        time.to_i
      }

      field :remain_seconds, ->(instance) {
        tpr = instance.user.inspect_test_paper_result
        return 0 if tpr.blank?
        time = tpr.created_at + instance.test_paper.minutes.minutes - Time.now
        time.to_i
      }

      field :test_wares_index, ->(instance) {
        instance.test_paper.sections.map do |section|
          {
            kind: section.kind,
            score: section.score,
            test_wares: section.questions.map do |question|
              filled = false
              tpr = instance.user.inspect_test_paper_result

              if tpr.blank?
                filled = false
              else
                answer_status = tpr.question_answer_status(question)
                filled = answer_status[:filled]
              end

              {
                id: question.id.to_s,
                filled: filled
              }
            end
          }
        end
      }

      logic :has_completed_reviews, ->(instance) {
        tpr = instance.user.inspect_test_paper_result
        return false if tpr.blank?
        tpr.has_completed_reviews?
      }

      url :reviews_url, ->(instance) {
        tpr = instance.user.inspect_test_paper_result
        return "" if tpr.blank?
        "/admin/test_results/#{tpr.id}/reviews"
      }

      url :admin_show_url, ->(instance) {
        tpr = instance.user.inspect_test_paper_result
        return "" if tpr.blank?
        "/admin/test_results/#{tpr.id}"
      }
    end

  end
end
