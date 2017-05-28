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
      module SummariesPdfHelper
        include ApplicationHelper
        # Returns a PDF string of a list of issues
        def summaries_to_pdf(data, title)

          #inicializo el pdf
          pdf = ITCPDF.new(current_language, "L")
          pdf.set_title(title)
          pdf.alias_nb_pages
          pdf.footer_date = format_date(User.current.today)
          pdf.set_auto_page_break(false)
          pdf.add_page("L")

          #obtengo la informacion del pdf
          page_height   = pdf.get_page_height # 210
          page_width    = pdf.get_page_width  # 297
          left_margin   = pdf.get_original_margins['left'] # 10
          right_margin  = pdf.get_original_margins['right'] # 10

          #escribo el titulo SCRUM
          pdf.SetFontStyle('B',14)
          pdf.RDMCell(35+155, 5, l(:label_scrum), '', 1)

          #centro y escribo el titulo
          center = (page_width/4.0)
          pdf.set_x(center)
          pdf.RDMCell(100, 5, title, 'B', 1)

          #defino las medidas de los rectangulos
          rectangle = {}
          width_and_margin = page_width/5.5
          rectangle['width'] = width_and_margin * 0.95
          rectangle['height'] = width_and_margin * 0.7
          rectangle['margin'] = width_and_margin * 0.05


          #defino el color de la linea y el fondo
          pdf.SetDrawColorArray([255, 207, 0])


          pdf.ln


          #se agregan los rectangulos de la primera fila
          set_rectangle(pdf, @data[:ta].length.to_s, l(:label_tasks_opened), [0,0,0], rectangle)
          set_rectangle(pdf, @data[:tr].length.to_s, l(:label_tasks_delayeds), [255,0,0], rectangle)
          set_rectangle(pdf, @data[:tr7].length.to_s, l(:label_due_on_7), [255,140,0], rectangle)
          set_rectangle(pdf, @data[:tr8].length.to_s, l(:label_due_on_8), [0,170,0], rectangle)
          set_rectangle(pdf, @data[:tr30].length.to_s, l(:label_due_on_30), [146,146,146], rectangle, true)

          #escribo el titulo Pendientes por cerrar
          pdf.SetFontStyle('B',14)
          pdf.SetTextColor(0,0,0)
          pdf.SetDrawColorArray([0, 0, 0])

          pending_close = "TAREAS PENDIENTES POR CERRAR"
          center = (page_width/4.0)
          pdf.set_x(center)
          pdf.RDMCell(100, 5, pending_close, 'B', 1)

          pdf.ln


          #defino el color de la linea y el fondo
          pdf.SetDrawColorArray([255, 207, 0])

          #dejo el espacio del cuadro que no aparece
          val_x = pdf.get_x + rectangle['width'] + rectangle['margin']
          pdf.set_xy(val_x, pdf.get_y)

          #se agregan los rectangulos de la segunda fila
          set_rectangle(pdf, @data[:tro].length.to_s, "#{l(:pending_close)}<br>#{l(:label_tasks_opened)}", [255,0,0], rectangle)
          set_rectangle(pdf, @data[:tro7].length.to_s, "#{l(:pending_close)}<br>#{l(:label_due_on_7)}", [255,140,0], rectangle)
          set_rectangle(pdf, @data[:tro8].length.to_s, "#{l(:pending_close)}<br>#{l(:label_due_on_8)}", [0,170,0], rectangle)
          set_rectangle(pdf, @data[:tro30].length.to_s, "#{l(:pending_close)}<br>#{l(:label_due_on_30)}", [146,146,146], rectangle, true)


          # Landscape A4 = 210 x 297 mm

          pdf.output
        end

        #dibuja un rectangle
        def set_rectangle(pdf, value, title, rgb, measures, ln = false)

          #guardo los valores iniciales para X y Y
          initial_x = pdf.get_x
          initial_y = pdf.get_y

          #añado el titulo gris al rectangulo
          pdf.SetTextColor(0,0,0)
          pdf.SetFontStyle('B',9)
          pdf.SetFillColorArray([202, 202, 202])
          SetTitleCell(pdf, measures['width'], 10, '', '', title,'LRBT', 1, 1)

          pdf.set_xy(initial_x, pdf.get_y)

          #añado el numero al rectangulo
          pdf.SetFillColorArray([255, 255, 255])
          pdf.SetFontStyle('B',35)
          pdf.SetTextColor(rgb[0],rgb[1],rgb[2])
          pdf.RDMCell(measures['width'], measures['height'], value, 'LRBT', 1, 'C', 1)

          #redefino X y Y
          if ln
            margins = pdf.getMargins
            val_y = initial_y + measures['height'] + 15
            pdf.set_xy(margins['left'], val_y)
          else
            val_x = initial_x + measures['width'] + measures['margin']
            pdf.set_xy(val_x, initial_y)
          end

        end

        def SetTitleCell(pdf, w, h, x, y, txt='', border=0, ln=1, fill=0)

          css_tag = ' <style>
          table, td {
            border: 2px #ff0000 solid;
          }
          th {  background-color:#EEEEEE; padding: 4px; white-space:nowrap; text-align: center;  font-style: bold;}
          pre {
            background-color: #fafafa;
          }
          </style>'

          # Strip {{toc}} tags
          txt.gsub!(/<p>\{\{([<>]?)toc\}\}<\/p>/i, '')
          pdf.writeHTMLCell(w, h, x, y, css_tag + txt, border, ln, fill, true, 'C')
        end
      end
    end
  end
end
