module EasyGanttPro
  module SuppressNotification

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :notify?, :easy_gantt_pro
      end
    end

    module InstanceMethods

      def notify_with_easy_gantt_pro?
        if RequestStore.store[:easy_gantt_suppress_notification] == true
          false
        else
          notify_without_easy_gantt_pro?
        end
      end

    end

  end
end

RedmineExtensions::PatchManager.register_model_patch ['Issue', 'Journal'], 'EasyGanttPro::SuppressNotification'
