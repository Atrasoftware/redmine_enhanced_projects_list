require_dependency 'projects_helper'

module  Patches
  module ProjectsHelperPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do
        include Redmine::I18n
        def self.fetch_row_project_values(project, cols, level)
          cols.collect do |column,val|
            s = if CustomField.where(:type=>"ProjectCustomField").where(:name=>column).present?
                  cv = project.visible_custom_field_values.detect {|v| v.custom_field.name == column}
                  cv.to_s
                else
                  value = project.send(column)
                  if column == :subject
                    value = "  " * level + value
                  end
                  if value.is_a?(Date)
                    value.to_s
                  elsif value.is_a?(Time)
                    value.to_s
                  else
                    value
                  end
                end
            s.to_s
          end
        end
        def self.calc_col_project_width(projects, cols, table_width, pdf)
          # calculate statistics
          #  by captions
          pdf.SetFontStyle('B',8)
          margins = pdf.get_margins
          col_padding = margins['cell']
          col_width_min = cols.map {|v| pdf.get_string_width(v) + col_padding}
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
          word_width_max = cols.map {|c|
            n = 10
            c.split.each {|w|
              x = pdf.get_string_width(w) + col_padding
              n = x if n < x
            }
            n
          }

          #  by properties of issues
          pdf.SetFontStyle('',8)
          k = 1
          Project.project_tree(projects) {|project, level|
            k += 1
            values = fetch_row_project_values(project, cols, level)
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

        def self.render_table_project_header(pdf, cols, col_width, row_height, table_width)
         # cols = hash.map{|k,v| k}

          # headers
          pdf.SetFontStyle('B',8)
          pdf.set_fill_color(230, 230, 230)
          base_x     = pdf.get_x
          base_y     = pdf.get_y
          max_height = get_projects_to_pdf_write_cells(pdf, cols, col_width)
          # write the cells on page
          cols.each_with_index do |column, i|
            pdf.RDMMultiCell(col_width[i], max_height, String.new(column), 1, '', 1, 0)
          end
          pdf.set_xy(base_x, base_y + max_height)
          # rows
          pdf.SetFontStyle('',8)
          pdf.set_fill_color(255, 255, 255)
        end

        def self.get_projects_to_pdf_write_cells(pdf, col_values, col_widths)
          heights = []
          col_values.each_with_index do |column, i|
            heights << pdf.get_string_height(col_widths[i], String.new(column))
          end
          return heights.max
        end



        def self.to_pdf(projects,settings,columns,current_language, order_desc= false)

          pdf = ::Redmine::Export::PDF::ITCPDF.new(current_language)

          pdf.alias_nb_pages
          disclosure_note = "The contents of this document are confidential and of solely property of Atra S.r.l. / www.atra.it © "
          pdf.footer_date = "#{disclosure_note}  #{format_time(DateTime.now)}"
          pdf.AddPage("L")

          pdf.SetX(15)

          pdf.Ln
         # pdf.SetFontStyle('B', 9)


         # Landscape A4 = 210 x 297 mm
          page_height   = pdf.get_page_height # 210
          page_width    = pdf.get_page_width  # 297
          left_margin   = pdf.get_original_margins['left'] # 10
          right_margin  = pdf.get_original_margins['right'] # 10
          bottom_margin = pdf.get_footer_margin
          row_height    = 4

          table_width = page_width - right_margin - left_margin
          col_width = []

          unless settings.empty?
            col_width = self.calc_col_project_width(projects, settings, table_width, pdf)
            table_width = col_width.inject(0, :+)
          end

          # use full width if the description is displayed
          if table_width > 0 && settings.has_key?(:description)
            col_width = col_width.map {|w| w * (page_width - right_margin - left_margin) / table_width}
            table_width = col_width.inject(0, :+)
          end

          # title
          pdf.SetFontStyle('B',11)
          pdf.RDMCell(190,10, "Projects")
          pdf.ln

          render_table_project_header(pdf, columns, col_width, row_height, table_width)
          # use full width if the description is displayed
tab =[]
          Project.project_tree_with_order(projects,order_desc) do |project, level|
            project_cells= Array.new
            project_cells<< "#{'    '*level}#{project.identifier}"
               if settings.present?
                   Project.column_names.select{|col| settings[col.to_sym] and col!= "identifier" }.each do |column|
                     project_cells<< project[column.to_sym]
                    end
                  CustomField.where(:type=> "ProjectCustomField").order("name ASC").select{|col| settings[col.name.to_sym] }.each do |cf|
                      project.visible_custom_field_values.select{|coll| coll.custom_field.name == cf.name }.each do |custom_value|
                          if custom_value.value.blank?
                            project_cells<< ""
                          else
                            project_cells<<   custom_value.value
                           end
                       end
                  end
               end
            cc = project_cells.collect{|value|
              if value.is_a?(Date)
                format_date(value)
              elsif value.is_a?(Time)
                format_time(value)
              else
                "#{value}"
              end
            }
             tab<< cc
          end

          tab.each do |cc|
            max_height = get_projects_to_pdf_write_cells(pdf,cc , col_width)
            cc.each_with_index do |column, i|
              pdf.RDMMultiCell(col_width[i], max_height, "#{column}", 1, '', 1, 0)
            end

            base_x     = pdf.get_x
            base_y     = pdf.get_y

            pdf.set_xy(base_x, base_y + max_height)

            # make new page if it doesn't fit on the current one
            base_y     = pdf.get_y
            max_height = get_projects_to_pdf_write_cells(pdf, cc, col_width)
            space_left = page_height - base_y - 2*bottom_margin
            if max_height > space_left
              pdf.add_page("L")
              pdf.ln
              render_table_project_header(pdf, columns, col_width, row_height, table_width)
            end
            pdf.set_x(10)
          end
          pdf.Output
        end

      end
    end
  end
  module ClassMethods
  end

  module InstanceMethods

  end

 end
