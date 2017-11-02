module MailerPatch
  def self.included(base) # :nodoc:
	base.send(:include, InstanceMethods)
		base.class_eval do

			def self.issue_diffused(issue)
				mails = issue.issue_attendees.select{|ia| !ia.invited? && !ia.user.blank? && !ia.user.mail.blank? && ia.user.mail_notification != 'none'}.map{|ia| ia.user.mail}
				mails.each do  |mail|
					mail_issue_diffused(mail, issue).deliver
				end
			end
			
			alias_method_chain :issue_add, :modification
			alias_method_chain :issue_edit, :modification

		end
	end



  def mail_issue_diffused(user, issue)
		@issue = issue
		@url = url_for(:controller => 'issues', :action => 'show', :id => issue.id)
		mail :to => user,
				 :subject => "Acta ##{Issue.find(issue.id).spmid} difundida"
	end

  #Función que envía notificaciones por errores en la sync de BPU
	def notification_bpu_sync(user, errors, user_number)
	  set_language_if_valid user.language
	  @user = user
	  @errors = errors
		@user_number = user_number
	  @login_url = url_for(:controller => 'account', :action => 'login')
	  mail :to => user.mail,
	       :subject => l(:mail_subject_bpu_sync, Setting.app_title)
	end

  module InstanceMethods

		# Builds a mail for notifying to_users and cc_users about an issue update
		def issue_edit_with_modification(journal, to_users, cc_users)
			issue = journal.journalized
			return nil if issue.recurrent?
			redmine_headers 'Project' => issue.project.identifier,
											'Issue-Id' => issue.id,
											'Issue-Author' => issue.author.login
			redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
			message_id journal
			references issue
			@author = journal.user
			s = "[#{issue.project.name} - ##{Issue.find(issue.id).spmid}] "
			s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
			s << issue.subject
			@issue = issue
			@users = to_users + cc_users
			@journal = journal
			@journal_details = journal.visible_details(@users.first)
			@issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")
			mail :to => to_users,
					 :cc => cc_users,
					 :subject => s
		end

		def issue_add_with_modification(issue, to_users, cc_users)
			return nil if issue.recurrent?
			redmine_headers 'Project' => issue.project.identifier,
											'Issue-Id' => issue.id,
											'Issue-Author' => issue.author.login
			redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
			message_id issue
			references issue
			@author = issue.author
			@issue = issue
			@users = to_users + cc_users
			@issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue)
			mail :to => to_users,
					 :cc => cc_users,
					 :subject => "[#{issue.project.name} - ##{Issue.find(issue.id).spmid}] (#{issue.status.name}) #{issue.subject}"
		end
		
	end
end