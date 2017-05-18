# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2016  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module Redmine
  module Export
    module PDF
      class MyPDF < ITCPDF
        def Header
          data = self.getHeaderData
          #self.Image("plugins/modifications/assets/images/header_sofasa.png",1,0, 200)
          self.SetFontStyle('B',15)
          self.SetTextColor(252, 210, 5)
          self.Write(0, "GROUPE", nil, 0, 'L')
          self.SetTextColor(0, 0, 0)
          self.Write(0, " RENAULT", nil, 0, 'L', true)
          self.SetFontStyle('B',9)
          self.Write(0, "RENAULT - Sofasa", nil, 0, 'L')
          self.SetFontStyle('B',6)
          self.SetTextColor(255, 0, 0)
          self.Write(0, data["title"], nil, 0, 'R', true)
          self.SetTextColor(0, 0, 0)
          self.SetFontStyle('B',15)
          self.Write(0, data["string"], nil, 0, 'C')

        end
      end
      module IssuesPdfModificationHelper
        class Utils
          include ApplicationHelper
          include IssuesHelper
          include ActionView::Helpers::NumberHelper
          include IssuesHelper
        end
        include Redmine:: I18n
        include ApplicationHelper
        include IssuesHelper

        def self.is_cjk?
          case current_language.to_s.downcase
            when 'ja', 'zh-tw', 'zh', 'ko'
              true
            else
              false
          end
        end

        # Returns a PDF string of a single issue
        def self.issue_to_pdf_modification(issue, assoc={})
          @issue ||= issue
          if issue.is_committee?

            pdf = MyPDF.new(current_language)
            pdf.set_print_header(true)
            pdf.set_margins(10, 30, 10)
            pdf.set_header_margin(10)

            #texto del encabezado
            issue_start_date = ''
            if issue.start_date
              issue_start_date = "#{issue.start_date.day}.#{issue.start_date.month}.#{issue.start_date.year}"
            end
            pdf.set_header_data("", 0, "RENAULT SECRET [A]", "Acta #{issue.subject ? issue.subject.to_s: ''}")


            pdf.set_title("#{issue.project} - ##{issue.spmid}")
            pdf.alias_nb_pages
            pdf.footer_date = format_date(issue.diffused_date) unless issue.diffused_date.blank?
            pdf.add_page
            pdf.SetFontStyle('B',12)
            buf = "##{issue.spmid}"
            pdf.RDMMultiCell(190, 5, buf)
            pdf.SetFontStyle('',9)
            base_x = pdf.get_x
            base_y = pdf.get_y
            i = 1
            issue.ancestors.visible.each do |ancestor|
              pdf.set_x(base_x + i)
              buf = "#{ancestor.tracker} # #{ancestor.id} (#{ancestor.status.to_s}): #{ancestor.subject}"
              pdf.RDMMultiCell(190 - i, 5, buf)
              i += 1 if i < 35
            end
            pdf.SetFontStyle('B',12)
            #pdf.RDMMultiCell(190 - i, 5,"#{issue.subject.to_s} - RENAULT Sofasa")
            pdf.SetFontStyle('',9)
            #pdf.RDMMultiCell(190, 5, "#{format_time(issue.created_on)} - #{issue.author}")
            #pdf.ln

            #pdf.line(10, pdf.get_y, 200, pdf.get_y)

            pdf.ln

            unless issue.description.nil? || issue.description.empty?
              pdf.SetFontStyle('B',10)
              pdf.RDMCell(35+155, 5, l(:field_description), "LRT", 1)
              pdf.SetFontStyle('',10)

              # Set resize image scale
              pdf.set_image_scale(1.6)
              text = Utils.new.textilizable(issue, :description,
                                            :only_path => false,
                                            :edit_section_links => false,
                                            :headings => false,
                                            :inline_attachments => false
              )
              pdf.RDMwriteFormattedCell(35+155, 5, '', '', text, [], "LRB")
              pdf.ln
            end

            left = []
            left << [l(:field_notes_by), issue.assigned_to] unless issue.disabled_core_fields.include?('assigned_to_id')

            right = []
            right << [l(:label_date), format_date(issue.start_date)] unless issue.disabled_core_fields.include?('start_date')



            rows = left.size > right.size ? left.size : right.size
            while left.size < rows
              left << nil
            end
            while right.size < rows
              right << nil
            end

            half = (issue.visible_custom_field_values.size / 2.0).ceil
            issue.visible_custom_field_values.each_with_index do |custom_value, i|
              (i < half ? left : right) << [custom_value.custom_field.name, show_value(custom_value, false)]
            end

            if pdf.get_rtl
              border_first_top = 'RT'
              border_last_top  = 'LT'
              border_first = 'R'
              border_last  = 'L'
            else
              border_first_top = 'LT'
              border_last_top  = 'RT'
              border_first = 'L'
              border_last  = 'R'
            end

            rows = left.size > right.size ? left.size : right.size
            rows.times do |i|
              heights = []
              pdf.SetFontStyle('B',10)
              item = left[i]
              heights << pdf.get_string_height(40, item ? "#{item.first}:" : "")
              item = right[i]
              heights << pdf.get_string_height(40, item ? "#{item.first}:" : "")
              pdf.SetFontStyle('',10)
              item = left[i]
              heights << pdf.get_string_height(55, item ? item.last.to_s  : "")
              item = right[i]
              heights << pdf.get_string_height(55, item ? item.last.to_s  : "")
              height = heights.max

              item = left[i]
              pdf.SetFontStyle('B',10)
              pdf.RDMMultiCell(40, height, item ? "#{item.first}:" : "", (i == 0 ? border_first_top : border_first), '', 0, 0)
              pdf.SetFontStyle('',10)
              pdf.RDMMultiCell(55, height, item ? item.last.to_s : "", (i == 0 ? border_last_top : border_last), '', 0, 0)

              item = right[i]
              pdf.SetFontStyle('B',10)
              pdf.RDMMultiCell(40, height, item ? "#{item.first}:" : "",  (i == 0 ? border_first_top : border_first), '', 0, 0)
              pdf.SetFontStyle('',10)
              pdf.RDMMultiCell(55, height, item ? item.last.to_s : "", (i == 0 ? border_last_top : border_last), '', 0, 2)

              pdf.set_x(base_x)
            end

            pdf.line(10, pdf.get_y, 200, pdf.get_y)

            pdf.set_y(pdf.get_y + 5)

            #pdf.SetFontStyle('B',9)
            #pdf.RDMCell(35+155, 5, l(:label_issue_attendants), "LRTB", 1)
            #pdf.SetFontStyle('',9)

            if pdf.get_rtl
              border_first_top = 'RT'
              border_last_top  = 'LT'
              border_first = 'R'
              border_last  = 'L'
            else
              border_first_top = 'L'
              border_last_top  = 'RT'
              border_first = 'L'
              border_last  = 'R'
            end

            attendants_left = []
            attendants_right = []
            attendants_center = []

            tmp = 0
            usr = []
            issue.issue_attendees.each do |ia|
              usr << ia.user_id
              if ! ia.invited
                attendants_left << ia.user.name
              else
                attendants_right << ia.user.name
              end
              tmp += 1
            end

            issue.project.users.where.not("#{Member.table_name}.user_id" => usr).each do |u|
              attendants_center << u.name
            end

            attendants_center = attendants_center.sort
            attendants_left = attendants_left.sort
            attendants_right = attendants_right.sort

            pdf.line(10, pdf.get_y, 200, pdf.get_y)

            if attendants_left.any?
              last_y = pdf.get_y
              pdf.SetFontStyle('B',10)
              pdf.Write(0, "#{l(:label_issue_attendants)}: ")
              pdf.SetFontStyle('',10)
              pdf.Write(0, "#{attendants_left.join(', ')}.")
              pdf.ln
              pdf.line(10, pdf.get_y, 200, pdf.get_y)
              pdf.line(10, last_y, 10, pdf.get_y)
              pdf.line(200, last_y, 200, pdf.get_y)
              pdf.ln
            end


            if attendants_right.any?
              last_y = pdf.get_y
              pdf.line(10, pdf.get_y, 200, pdf.get_y)
              pdf.SetFontStyle('B',10)
              pdf.Write(0, "#{l(:label_inviteds)}: ")
              pdf.SetFontStyle('',10)
              pdf.Write(0, "#{attendants_right.join(', ')}.")
              pdf.ln
              pdf.line(10, pdf.get_y, 200, pdf.get_y)
              pdf.line(10, last_y, 10, pdf.get_y)
              pdf.line(200, last_y, 200, pdf.get_y)
              pdf.ln
            end


            if attendants_center.any?
              pdf.line(10, pdf.get_y, 200, pdf.get_y)
              last_y = pdf.get_y
              pdf.SetFontStyle('B',10)
              pdf.Write(0, "#{l(:label_issue_missings)}: ")
              pdf.SetFontStyle('',10)
              pdf.Write(0, "#{attendants_center.join(', ')}.")
              pdf.ln
              pdf.line(10, pdf.get_y, 200, pdf.get_y)
              pdf.line(10, last_y, 10, pdf.get_y)
              pdf.line(200, last_y, 200, pdf.get_y)
              pdf.ln
            end

            if issue.others && issue.others != ''
              pdf.line(10, pdf.get_y, 200, pdf.get_y)
              last_y = pdf.get_y
              pdf.SetFontStyle('B',10)
              pdf.Write(0, "#{l(:label_others)}: ")
              pdf.SetFontStyle('',10)
              pdf.Write(0, issue.others)
              pdf.ln
              pdf.line(10, pdf.get_y, 200, pdf.get_y)
              pdf.line(10, last_y, 10, pdf.get_y)
              pdf.line(200, last_y, 200, pdf.get_y)
            end


            pdf.SetFontStyle('',10)
            #pdf.RDMMultiCell(190, 5, l(:label_text_after_users_pdf))

            pdf.ln


            i_topic = 1

            issue.topics.each do |topic|


              height_presented_by = (!topic.presented_by.blank?) ? pdf.get_string_height(55, topic.presented_by) : 5
              height_detail = (!topic.detail.blank?) ? pdf.get_string_height(55, topic.detail) : 5
              height = height_presented_by > height_detail ? height_presented_by : height_detail

              pdf.SetFontStyle('B',10)
              pdf.RDMMultiCell(40, height, !topic.presented_by.blank? ? "#{l(:label_presented_by)}:" : '', '', '', 0, 0)
              pdf.SetFontStyle('',10)
              pdf.RDMMultiCell(55, height, !topic.presented_by.blank? ? topic.presented_by : '', '', '', 0, 0)

              pdf.SetFontStyle('B',10)
              pdf.RDMMultiCell(40, height, !topic.detail.blank? ? "#{l(:label_detail)}:" : '', '', '', 0, 0)
              pdf.SetFontStyle('',10)
              pdf.RDMMultiCell(55, height, !topic.detail.blank? ? topic.detail : '', '', '', 0, 2)

              pdf.set_y(pdf.get_y)

              pdf.SetFontStyle('B',10)
              pdf.RDMMultiCell(40, 5, l(:label_topic_number, :number => i_topic), '', '', 0, 2)

              pdf.set_y(pdf.get_y)

              pdf.SetFontStyle('',10)
              # Set resize image scale
              pdf.set_image_scale(1.6)
              text = Utils.new.textilizable(topic, :content,
                                            :only_path => false,
                                            :edit_section_links => false,
                                            :headings => false,
                                            :inline_attachments => false
              )
              pdf.RDMwriteFormattedCell(35+155, 5, '', '', text, [], "B")

              i_topic += 1

              if (pdf.get_y + 12).round(2) > 268
                pdf.add_page
              end

              new_page = false
              if topic.issue_topics.any?

                if topic.issue_topics.select{|it| it.issue && it.issue.tracker_id.to_i == Setting.default_application_for_task.to_i}.any?

                  pdf.SetFontStyle('B',10)
                  pdf.RDMMultiCell(25, 6, l(:field_number_task), "LTB", '', 0, 0)
                  pdf.RDMMultiCell(100, 6, l(:field_task), "LTB", '', 0, 0)
                  pdf.RDMMultiCell(40, 6, l(:field_assigned_to), "LTB", '', 0, 0)
                  pdf.RDMMultiCell(25, 6, l(:field_term_date_pdf), "LRTB", '', 0, 0)

                  pdf.SetFontStyle('',10)
                  #pdf.ln
                  pdf.set_x(base_x)
                  pdf.set_y(pdf.get_y + 6)
                  topic.issue_topics.each do |it|
                    next if it.issue.nil? || it.issue.tracker_id.to_i != Setting.default_application_for_task.to_i
                    is = it.issue
                    heights = []
                    heights << pdf.get_string_height(25, l(:field_number_task))
                    is.subject = "#{is.topic.first.detail}: " + is.subject if (is.is_task? || is.is_desition?) && is.topic.first && !is.topic.first.detail.blank?
                    heights << pdf.get_string_height(100, is.subject)
                    heights << pdf.get_string_height(40, is.assigned_to.to_s)
                    heights << pdf.get_string_height(25, (is.due_date ? format_date(is.due_date) : ''))

                    height = heights.max

                    if (pdf.get_y + height).round(2) > 268
                      pdf.add_page
                      new_page = true
                    end

                    #pdf.line(10, pdf.get_y + height, 200, pdf.get_y + height)

                    pdf.RDMMultiCell(25, height, is.spmid.to_s, "LTB", '', 0, 0)
                    pdf.RDMMultiCell(100, height, is.subject, "LTB", '', 0, 0)
                    pdf.RDMMultiCell(40, height, is.assigned_to.to_s, "LTB", '', 0, 0)
                    pdf.RDMMultiCell(25, height,( is.due_date ? format_date(is.due_date) : ''), "LRTB", '', 0, 0)
                    #pdf.ln
                    pdf.set_y(pdf.get_y + height)
                    pdf.set_x(base_x)
                  end

                  pdf.SetFontStyle('',10)
                  pdf.set_y(pdf.get_y + 5)
                end

                if topic.issue_topics.select{|it| it.issue && it.issue.tracker_id.to_i == 5}.any?

                  pdf.SetFontStyle('B',10)
                  pdf.RDMMultiCell(25, 6, l(:field_number_task), "LTB", '', 0, 0)
                  pdf.RDMMultiCell(125, 6, l(:field_desition), "LTB", '', 0, 0)
                  pdf.RDMMultiCell(40, 6, l(:field_application_date), "LRTB", '', 0, 0)

                  pdf.SetFontStyle('',10)
                  #pdf.ln
                  pdf.set_x(base_x)
                  pdf.set_y(pdf.get_y + 6)
                  topic.issue_topics.each do |it|
                    next if it.issue.nil? || it.issue.tracker_id.to_i != 5
                    is = it.issue
                    heights = []
                    heights << pdf.get_string_height(25, l(:field_number_task))
                    is.subject = "#{is.topic.first.detail}: " + is.subject if (is.is_task? || is.is_desition?) && is.topic.first && !is.topic.first.detail.blank?
                    heights << pdf.get_string_height(125, is.subject)
                    heights << pdf.get_string_height(40, (is.due_date ? format_date(is.due_date) : ''))

                    height = heights.max

                    if (pdf.get_y + height).round(2) > 268
                      pdf.add_page
                      new_page = true
                    end

                    #pdf.line(10, pdf.get_y + height, 200, pdf.get_y + height)

                    pdf.RDMMultiCell(25, height, is.spmid.to_s, "LTB", '', 0, 0)
                    pdf.RDMMultiCell(125, height, is.subject, "LTB", '', 0, 0)
                    pdf.RDMMultiCell(40, height,( is.due_date ? format_date(is.due_date) : ''), "LRTB", '', 0, 0)
                    #pdf.ln
                    pdf.set_y(pdf.get_y + height)
                    pdf.set_x(base_x)
                  end

                  pdf.SetFontStyle('',10)
                  pdf.set_y(pdf.get_y + 5)
                end

              else
                pdf.set_y(pdf.get_y + 5)
              end

            end


            pdf.ln


            text = Setting.pdf_signature_for_committees

            pdf.RDMMultiCell(35+155, 30,text)


            pdf.output
          else


            pdf = MyPDF.new(current_language)
            pdf.set_print_header(true)
            pdf.set_margins(10, 25, 10)
            pdf.set_header_margin(10)
            #texto del encabezado
            issue_start_date = ''
            if issue.start_date
              issue_start_date = "#{issue.start_date.day}.#{issue.start_date.month}.#{issue.start_date.year}"
            end
            #pdf.set_header_data("", 0, "", "#{issue.subject ? issue.subject.to_s : ''}")

            pdf.set_title("#{issue.project} - ##{issue.spmid}")
            pdf.alias_nb_pages
            pdf.footer_date = format_date(issue.diffused_date) unless issue.diffused_date.blank?
            pdf.add_page

            pdf.SetFontStyle('B',11)
            buf = "##{issue.spmid}"
            pdf.RDMMultiCell(190, 5, buf)
            pdf.SetFontStyle('',8)
            base_x = pdf.get_x
            i = 1
            issue.ancestors.visible.each do |ancestor|
              pdf.set_x(base_x + i)
              buf = "#{ancestor.tracker} ##{ancestor.spmid} (#{ancestor.status.to_s}): #{ancestor.subject}"
              pdf.RDMMultiCell(190 - i, 5, buf)
              i += 1 if i < 35
            end
            pdf.SetFontStyle('B',11)
            pdf.RDMMultiCell(190 - i, 5, issue.subject.to_s)
            pdf.SetFontStyle('',8)
            pdf.RDMMultiCell(190, 5, "#{format_time(issue.created_on)} - #{issue.author}")
            pdf.ln

            left = []
            left << [l(:field_status), issue.status]
            #left << [l(:field_priority), issue.priority]
            left << [l(:field_assigned_to), issue.assigned_to] unless issue.disabled_core_fields.include?('assigned_to_id') || issue.is_desition?
            left << [l(:field_category), issue.category] unless issue.disabled_core_fields.include?('category_id') || issue.category.blank?
            left << [l(:field_fixed_version), issue.fixed_version] unless issue.disabled_core_fields.include?('fixed_version_id') || issue.fixed_version.blank?
            left << [l(:field_direction), issue.direction] if issue.is_task?
            left << [l(:field_origin), issue.origin] if (issue.is_task? || issue.is_desition?)
            #left << [l(:field_task_type), issue.task_type] if (issue.is_task? || issue.is_desition?)

            right = []
            right << [l(:field_registration_date), format_date(issue.start_date)] unless issue.disabled_core_fields.include?('start_date') || issue.is_desition?
            right << [((issue.is_desition?) ? l(:field_application_date) : l(:field_due_date)), format_date(issue.due_date)] unless issue.disabled_core_fields.include?('due_date')
            right << [l(:field_compliance_date), issue.compliance_date] if issue.is_task?
            right << [l(:field_done_ratio), "#{issue.done_ratio}%"] unless issue.disabled_core_fields.include?('done_ratio')
            right << [l(:field_estimated_hours), l_hours(issue.estimated_hours)] unless issue.disabled_core_fields.include?('estimated_hours')
            right << [l(:label_spent_time), l_hours(issue.total_spent_hours)] if User.current.allowed_to?(:view_time_entries, issue.project)
            right << [l(:field_vision), issue.vision] if (issue.is_task? || issue.is_desition?)


            rows = left.size > right.size ? left.size : right.size
            while left.size < rows
              left << nil
            end
            while right.size < rows
              right << nil
            end

            half = (issue.visible_custom_field_values.size / 2.0).ceil
            issue.visible_custom_field_values.each_with_index do |custom_value, i|
              (i < half ? left : right) << [custom_value.custom_field.name, show_value(custom_value, false)]
            end

            if pdf.get_rtl
              border_first_top = 'RT'
              border_last_top  = 'LT'
              border_first = 'R'
              border_last  = 'L'
            else
              border_first_top = 'LT'
              border_last_top  = 'RT'
              border_first = 'L'
              border_last  = 'R'
            end

            rows = left.size > right.size ? left.size : right.size
            rows.times do |i|
              heights = []
              pdf.SetFontStyle('B',9)
              item = left[i]
              heights << pdf.get_string_height(35, item ? "#{item.first}:" : "")
              item = right[i]
              heights << pdf.get_string_height(35, item ? "#{item.first}:" : "")
              pdf.SetFontStyle('',9)
              item = left[i]
              heights << pdf.get_string_height(60, item ? item.last.to_s  : "")
              item = right[i]
              heights << pdf.get_string_height(60, item ? item.last.to_s  : "")
              height = heights.max

              item = left[i]
              pdf.SetFontStyle('B',9)
              pdf.RDMMultiCell(35, height, item ? "#{item.first}:" : "", (i == 0 ? border_first_top : border_first), '', 0, 0)
              pdf.SetFontStyle('',9)
              pdf.RDMMultiCell(60, height, item ? item.last.to_s : "", (i == 0 ? border_last_top : border_last), '', 0, 0)

              item = right[i]
              pdf.SetFontStyle('B',9)
              pdf.RDMMultiCell(35, height, item ? "#{item.first}:" : "",  (i == 0 ? border_first_top : border_first), '', 0, 0)
              pdf.SetFontStyle('',9)
              pdf.RDMMultiCell(60, height, item ? item.last.to_s : "", (i == 0 ? border_last_top : border_last), '', 0, 2)

              pdf.set_x(base_x)
            end

            pdf.SetFontStyle('B',9)
            pdf.RDMCell(35+155, 5, l(:field_description), "LRT", 1)
            pdf.SetFontStyle('',9)

            # Set resize image scale
            pdf.set_image_scale(1.6)
            text = Utils.new.textilizable(issue, :description,
                                :only_path => false,
                                :edit_section_links => false,
                                :headings => false,
                                :inline_attachments => false
            )
            pdf.RDMwriteFormattedCell(35+155, 5, '', '', text, issue.attachments, "LRB")

            unless issue.leaf?
              truncate_length = (!is_cjk? ? 90 : 65)
              pdf.SetFontStyle('B',9)
              pdf.RDMCell(35+155,5, l(:label_subtask_plural) + ":", "LTR")
              pdf.ln
              Utils.new.issue_list(issue.descendants.visible.sort_by(&:lft)) do |child, level|
                buf = "#{child.tracker} ##{child.spmid}: #{child.subject}".
                  truncate(truncate_length)
                level = 10 if level >= 10
                pdf.SetFontStyle('',8)
                pdf.RDMCell(35+135,5, (level >=1 ? "  " * level : "") + buf, border_first)
                pdf.SetFontStyle('B',8)
                pdf.RDMCell(20,5, child.status.to_s, border_last)
                pdf.ln
              end
            end

            relations = issue.relations.select { |r| r.other_issue(issue).visible? }
            unless relations.empty?
              truncate_length = (!is_cjk? ? 80 : 60)
              pdf.SetFontStyle('B',9)
              pdf.RDMCell(35+155,5, l(:label_related_issues) + ":", "LTR")
              pdf.ln
              relations.each do |relation|
                buf = relation.to_s(issue) {|other|
                  text = ""
                  if Setting.cross_project_issue_relations?
                    text += "#{relation.other_issue(issue).project} - "
                  end
                  text += "#{other.tracker} ##{other.spmid}: #{other.subject}"
                  text
                }
                buf = buf.truncate(truncate_length)
                pdf.SetFontStyle('', 8)
                pdf.RDMCell(35+155-60, 5, buf, border_first)
                pdf.SetFontStyle('B',8)
                pdf.RDMCell(20,5, relation.other_issue(issue).status.to_s, "")
                pdf.RDMCell(20,5, format_date(relation.other_issue(issue).start_date), "")
                pdf.RDMCell(20,5, format_date(relation.other_issue(issue).due_date), border_last)
                pdf.ln
              end
            end
            pdf.RDMCell(190,5, "", "T")
            pdf.ln

            if issue.changesets.any? &&
              User.current.allowed_to?(:view_changesets, issue.project)
              pdf.SetFontStyle('B',9)
              pdf.RDMCell(190,5, l(:label_associated_revisions), "B")
              pdf.ln
              for changeset in issue.changesets
                pdf.SetFontStyle('B',8)
                csstr  = "#{l(:label_revision)} #{changeset.format_identifier} - "
                csstr += format_time(changeset.committed_on) + " - " + changeset.author.to_s
                pdf.RDMCell(190, 5, csstr)
                pdf.ln
                unless changeset.comments.blank?
                  pdf.SetFontStyle('',8)
                  pdf.RDMwriteHTMLCell(190,5,'','',
                                       changeset.comments.to_s, issue.attachments, "")
                end
                pdf.ln
              end
            end

            if assoc[:journals].present?
              pdf.SetFontStyle('B',9)
              pdf.RDMCell(190,5, l(:label_history), "B")
              pdf.ln
              assoc[:journals].each do |journal|
                pdf.SetFontStyle('B',8)
                title = "##{journal.indice} - #{format_time(journal.created_on)} - #{journal.user}"
                title << " (#{l(:field_private_notes)})" if journal.private_notes?
                pdf.RDMCell(190,5, title)
                pdf.ln
                pdf.SetFontStyle('I',8)
                Utils.new.details_to_strings(journal.visible_details, true).each do |string|
                  pdf.RDMMultiCell(190,5, "- " + string)
                end
                if journal.notes?
                  pdf.ln unless journal.details.empty?
                  pdf.SetFontStyle('',8)
                  text = Utils.new.textilizable(journal, :notes,
                                      :only_path => false,
                                      :edit_section_links => false,
                                      :headings => false,
                                      :inline_attachments => false
                  )
                  pdf.RDMwriteFormattedCell(190,5,'','', text, issue.attachments, "")
                end
                pdf.ln
              end
            end

            if issue.attachments.any?
              pdf.SetFontStyle('B',9)
              pdf.RDMCell(190,5, l(:label_attachment_plural), "B")
              pdf.ln
              for attachment in issue.attachments
                pdf.SetFontStyle('',8)
                pdf.RDMCell(80,5, attachment.filename)
                pdf.RDMCell(20,5, ActiveSupport::NumberHelper.number_to_human_size(attachment.filesize),0,0,"R")
                pdf.RDMCell(25,5, format_date(attachment.created_on),0,0,"R")
                pdf.RDMCell(65,5, attachment.author.name,0,0,"R")
                pdf.ln
              end
            end
            pdf.output




          end
        end

        # Returns a PDF string of a list of issues
        def self.issues_to_pdf_modification(issues, project, query)
          pdf = ITCPDF.new(current_language, "L")
          title = query.new_record? ? l(:label_issue_plural) : query.name
          title = "#{project} - #{title}" if project
          pdf.set_title(title)
          pdf.alias_nb_pages
          pdf.footer_date = format_date(User.current.today)
          pdf.set_auto_page_break(false)
          pdf.add_page("L")

          # Landscape A4 = 210 x 297 mm
          page_height   = pdf.get_page_height # 210
          page_width    = pdf.get_page_width  # 297
          left_margin   = pdf.get_original_margins['left'] # 10
          right_margin  = pdf.get_original_margins['right'] # 10
          bottom_margin = pdf.get_footer_margin
          row_height    = 4

          # column widths
          table_width = page_width - right_margin - left_margin
          col_width = []
          unless query.inline_columns.empty?
            col_width = calc_col_width(issues, query, table_width, pdf)
            table_width = col_width.inject(0, :+)
          end

          # use full width if the description is displayed
          if table_width > 0 && query.has_column?(:description)
            col_width = col_width.map {|w| w * (page_width - right_margin - left_margin) / table_width}
            table_width = col_width.inject(0, :+)
          end

          # title
          pdf.SetFontStyle('B',11)
          pdf.RDMCell(190, 8, title)
          pdf.ln

          # totals
          totals = query.totals.map {|column, total| "#{column.caption}: #{total}"}
          if totals.present?
            pdf.SetFontStyle('B',10)
            pdf.RDMCell(table_width, 6, totals.join("  "), 0, 1, 'R')
          end

          totals_by_group = query.totals_by_group
          render_table_header(pdf, query, col_width, row_height, table_width)
          previous_group = false
          Utils.new.issue_list(issues) do |issue, level|
            if query.grouped? &&
              (group = query.group_by_column.value(issue)) != previous_group
              pdf.SetFontStyle('B',10)
              group_label = group.blank? ? 'None' : group.to_s.dup
              group_label << " (#{query.issue_count_by_group[group]})"
              pdf.bookmark group_label, 0, -1
              pdf.RDMCell(table_width, row_height * 2, group_label, 'LR', 1, 'L')
              pdf.SetFontStyle('',8)

              totals = totals_by_group.map {|column, total| "#{column.caption}: #{total[group]}"}.join("  ")
              if totals.present?
                pdf.RDMCell(table_width, row_height, totals, 'LR', 1, 'L')
              end
              previous_group = group
            end

            # fetch row values
            col_values = fetch_row_values(issue, query, level)

            # make new page if it doesn't fit on the current one
            base_y     = pdf.get_y
            max_height = get_issues_to_pdf_write_cells(pdf, col_values, col_width)
            space_left = page_height - base_y - bottom_margin
            if max_height > space_left
              pdf.add_page("L")
              render_table_header(pdf, query, col_width, row_height, table_width)
              base_y = pdf.get_y
            end

            # write the cells on page
            issues_to_pdf_write_cells(pdf, col_values, col_width, max_height,false , issue)
            pdf.set_y(base_y + max_height)

            if query.has_column?(:description) && issue.description?
              pdf.set_x(10)
              pdf.set_auto_page_break(true, bottom_margin)
              pdf.RDMwriteHTMLCell(0, 5, 10, '', issue.description.to_s, issue.attachments, "LRBT")
              pdf.set_auto_page_break(false)
            end
          end

          if issues.size == Setting.issues_export_limit.to_i
            pdf.SetFontStyle('B',10)
            pdf.RDMCell(0, row_height, '...')
          end
          pdf.output



        end

        def is_cjk?
          case current_language.to_s.downcase
            when 'ja', 'zh-tw', 'zh', 'ko'
              true
            else
              false
          end
        end

        # fetch row values
        def self.fetch_row_values(issue, query, level)
          query.inline_columns.collect do |column|
            s = if column.is_a?(QueryCustomFieldColumn)
              cv = issue.visible_custom_field_values.detect {|v| v.custom_field_id == column.custom_field.id}
              show_value(cv, false)
            else
              value = issue.send(column.name)
              if column.name == :subject
                value = "  " * level + value
              end
              if value.is_a?(Date)
                format_date(value)
              elsif value.is_a?(Time)
                format_time(value)
              else
                value
              end
            end
            s.to_s
          end
        end

        # calculate columns width
        def self.calc_col_width(issues, query, table_width, pdf)
          # calculate statistics
          #  by captions
          pdf.SetFontStyle('B',8)
          margins = pdf.get_margins
          col_padding = margins['cell']
          col_width_min = query.inline_columns.map {|v| pdf.get_string_width(v.caption) + col_padding}
          col_width_max = Array.new(col_width_min)
          col_width_avg = Array.new(col_width_min)
          col_min = pdf.get_string_width('OO') + col_padding * 2
          if table_width > col_min * col_width_avg.length
            table_width -= col_min * col_width_avg.length
          else
            col_min = pdf.get_string_width('O') + col_padding * 2
            if table_width > col_min * col_width_avg.length
              table_width -= col_min * col_width_avg.length
            else
              ratio = table_width / col_width_avg.inject(0, :+)
              return col_width = col_width_avg.map {|w| w * ratio}
            end
          end
          word_width_max = query.inline_columns.map {|c|
            n = 10
            c.caption.split.each {|w|
              x = pdf.get_string_width(w) + col_padding
              n = x if n < x
            }
            n
          }

          #  by properties of issues
          pdf.SetFontStyle('',8)
          k = 1
          Utils.new.issue_list(issues) {|issue, level|
            k += 1
            values = fetch_row_values(issue, query, level)
            values.each_with_index {|v,i|
              n = pdf.get_string_width(v) + col_padding * 2
              col_width_max[i] = n if col_width_max[i] < n
              col_width_min[i] = n if col_width_min[i] > n
              col_width_avg[i] += n
              v.split.each {|w|
                x = pdf.get_string_width(w) + col_padding
                word_width_max[i] = x if word_width_max[i] < x
              }
            }
          }
          col_width_avg.map! {|x| x / k}

          # calculate columns width
          ratio = table_width / col_width_avg.inject(0, :+)
          col_width = col_width_avg.map {|w| w * ratio}

          # correct max word width if too many columns
          ratio = table_width / word_width_max.inject(0, :+)
          word_width_max.map! {|v| v * ratio} if ratio < 1

          # correct and lock width of some columns
          done = 1
          col_fix = []
          col_width.each_with_index do |w,i|
            if w > col_width_max[i]
              col_width[i] = col_width_max[i]
              col_fix[i] = 1
              done = 0
            elsif w < word_width_max[i]
              col_width[i] = word_width_max[i]
              col_fix[i] = 1
              done = 0
            else
              col_fix[i] = 0
            end
          end

          # iterate while need to correct and lock coluns width
          while done == 0
            # calculate free & locked columns width
            done = 1
            ratio = table_width / col_width.inject(0, :+)

            # correct columns width
            col_width.each_with_index do |w,i|
              if col_fix[i] == 0
                col_width[i] = w * ratio

                # check if column width less then max word width
                if col_width[i] < word_width_max[i]
                  col_width[i] = word_width_max[i]
                  col_fix[i] = 1
                  done = 0
                elsif col_width[i] > col_width_max[i]
                  col_width[i] = col_width_max[i]
                  col_fix[i] = 1
                  done = 0
                end
              end
            end
          end

          ratio = table_width / col_width.inject(0, :+)
          col_width.map! {|v| v * ratio + col_min}
          col_width
        end

        def self.render_table_header(pdf, query, col_width, row_height, table_width)
          # headers
          pdf.SetFontStyle('B',8)
          pdf.set_fill_color(230, 230, 230)

          base_x     = pdf.get_x
          base_y     = pdf.get_y
          max_height = get_issues_to_pdf_write_cells(pdf, query.inline_columns, col_width, true)

          # write the cells on page
          issues_to_pdf_write_cells(pdf, query.inline_columns, col_width, max_height, true)
          pdf.set_xy(base_x, base_y + max_height)

          # rows
          pdf.SetFontStyle('',8)
          pdf.set_fill_color(255, 255, 255)
        end

        # returns the maximum height of MultiCells
        def self.get_issues_to_pdf_write_cells(pdf, col_values, col_widths, head=false)
          heights = []
          col_values.each_with_index do |column, i|
            heights << pdf.get_string_height(col_widths[i], head ? column.caption : column)
          end
          return heights.max
        end

        # Renders MultiCells and returns the maximum height used
        def self.issues_to_pdf_write_cells(pdf, col_values, col_widths, row_height, head=false, issue = nil)
          col_values.each_with_index do |column, i|
            if issue && column == issue.id.to_s
              pdf.RDMMultiCell(col_widths[i], row_height, issue.spmid, 1, '', 1, 0)
            else
              pdf.RDMMultiCell(col_widths[i], row_height, head ? column.caption : column.strip, 1, '', 1, 0)
            end

          end
        end

        # Draw lines to close the row (MultiCell border drawing in not uniform)
        #
        #  parameter "col_id_width" is not used. it is kept for compatibility.
        def issues_to_pdf_draw_borders(pdf, top_x, top_y, lower_y,
                                       col_id_width, col_widths, rtl=false)
          col_x = top_x
          pdf.line(col_x, top_y, col_x, lower_y)    # id right border
          col_widths.each do |width|
            if rtl
              col_x -= width
            else
              col_x += width
            end
            pdf.line(col_x, top_y, col_x, lower_y)  # columns right border
          end
          pdf.line(top_x, top_y, top_x, lower_y)    # left border
          pdf.line(top_x, lower_y, col_x, lower_y)  # bottom border
        end
      end
    end
  end
end
