module IssueImportPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    base.class_eval do

      alias_method_chain :build_object, :modification
    end

    def allowed_target_trackers_for_project project_id
      Issue.allowed_target_trackers(project_for_project(project_id), user)
    end

    def project_for_project project_id
      allowed_target_projects.find_by_id(project_id) || allowed_target_projects.first
    end

  end
  module InstanceMethods
    def build_object_with_modification(row)
      issue = Issue.new
      if mapping['tracker_id'] == Setting.default_application_for_committee
        if subject = row_value(row, 'subject')
          if start_date = row_date(row, 'start_date')
            if issue_actual = Issue.find_by(:subject => subject, :tracker_id => mapping['tracker_id'], :start_date =>  start_date, :project_id => mapping['project_id'])
              issue = issue_actual.clone
            end
         end
        end
      end

      issue.author = user
      issue.notify = false
      attributes = {
          'project_id' => mapping['project_id'],
          'tracker_id' => mapping['tracker_id'],
          'subject' => row_value(row, 'subject'),
          'description' => row_value(row, 'description'),
          'estimated_hours' => row_value(row, 'estimated_hours')
      }
      issue.send :safe_attributes=, attributes, user
      attributes = {}
      if priority_name = row_value(row, 'priority')
        if priority_id = IssuePriority.active.named(priority_name).first.try(:id)
          attributes['priority_id'] = priority_id
        end
      end
      if issue.project && category_name = row_value(row, 'category')
        if category = issue.project.issue_categories.named(category_name).first
          attributes['category_id'] = category.id
        elsif create_categories?
          category = issue.project.issue_categories.build
          category.name = category_name
          if category.save
            attributes['category_id'] = category.id
          end
        end
      end
      if assignee_name = row_value(row, 'assigned_to')
        if assignee = Principal.detect_by_keyword(issue.assignable_users, assignee_name)
          attributes['assigned_to_id'] = assignee.id
        end
      end
      if issue.project && version_name = row_value(row, 'fixed_version')
        if version = issue.project.versions.named(version_name).first
          attributes['fixed_version_id'] = version.id
        elsif create_versions?
          version = issue.project.versions.build
          version.name = version_name
          if version.save
            attributes['fixed_version_id'] = version.id
          end
        end
      end
      if is_private = row_value(row, 'is_private')
        if yes?(is_private)
          attributes['is_private'] = '1'
        end
      end
      if parent_issue_id = row_value(row, 'parent_issue_id')
        if parent_issue_id =~ /\A(#)?(\d+)\z/
          parent_issue_id = $2
          if $1
            attributes['parent_issue_id'] = parent_issue_id
          elsif issue_id = items.where(:position => parent_issue_id).first.try(:obj_id)
            attributes['parent_issue_id'] = issue_id
          end
        else
          attributes['parent_issue_id'] = parent_issue_id
        end
      end
      if start_date = row_date(row, 'start_date')
        attributes['start_date'] = start_date
      end
      if due_date = row_date(row, 'due_date')
        attributes['due_date'] = due_date
      end
      if done_ratio = row_value(row, 'done_ratio')
        attributes['done_ratio'] = done_ratio
      end

      attributes['custom_field_values'] = issue.custom_field_values.inject({}) do |h, v|
        value = case v.custom_field.field_format
                  when 'date'
                    row_date(row, "cf_#{v.custom_field.id}")
                  else
                    row_value(row, "cf_#{v.custom_field.id}")
                end
        if value
          h[v.custom_field.id.to_s] = v.custom_field.value_from_keyword(value, issue)
        end
        h
      end

      issue.send :safe_attributes=, attributes, user

      if issue.is_committee?
        #se obtiene el topico
        topic = Topic.new
        if topic_actual = Topic.find_by(:content => row_value(row, 'topic_content'), :issue_id => issue.id.to_s)
          topic = topic_actual.clone
        end

        if content = row_value(row, 'topic_content')
          topic.content = content
        end

        topic_issue = Issue.new

        if project_name = row_value(row, 'topic_task_project')
          topic_issue.project = Project.find_by_name(project_name) rescue nil
        end

        topic_issue.origin_id = (Committee.find_by_name(issue.subject).id rescue Committee.first.id)

        if subject = row_value(row, 'topic_task_subject')
          topic_issue.subject = subject
        end

        if assignee_name = row_value(row, 'topic_task_assigned_to')
          if assignee = Principal.detect_by_keyword(issue.assignable_users, assignee_name)
            topic_issue.assigned_to_id = assignee.id
          end
        end

        topic_issue.direction_id = !topic_issue.assigned_to_id.blank? ? User.find(topic_issue.assigned_to_id).direction_id : ""

        if start_date = row_date(row, 'start_date')
          topic_issue.start_date = start_date
        end

        if due_date = row_date(row, 'topic_task_due_date')
          topic_issue.due_date = due_date
        end

        if type_name = row_value(row, 'topic_task_type')
          topic_issue.task_type_id = TaskType.find_by_name(type_name).id rescue TaskType.first.id
        end

        if status = row_value(row, 'topic_task_status')
          topic_issue.status_id = IssueStatus.find_by_name(status).id rescue IssueStatus.first.id
        end

        if priority = row_value(row, 'topic_task_priority')
          topic_issue.priority_id = IssuePriority.find_by_name(priority).id rescue IssuePriority.first.id
        end

        if notes = row_value(row, 'topic_task_notes')
          topic_issue.description = notes
        end

        topic_issue.tracker_id = Setting.default_application_for_task.to_i
        topic_issue.author_id = User.current.id
        topic_issue.parent = issue

        issue_topic = IssueTopic.new
        issue_topic.issue =  topic_issue
        issue_topic.topic = topic

        topic.issue_topics << issue_topic

        issue.topics << topic

      end

      issue
    end
  end
end