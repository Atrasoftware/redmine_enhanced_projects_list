require_dependency 'projects_helper'

module  Patches
  module ProjectsHelperPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do

        def render_table_header(pdf, query, col_width, row_height, table_width)
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

        def self.to_pdf(projects,settings,current_language)

          pdf = ::Redmine::Export::PDF::ITCPDF.new(current_language)
          pdf.SetTitle("PROJECT INDEX")
          pdf.alias_nb_pages
          pdf.AddPage("L")

          pdf.SetX(15)
          pdf.RDMCell(100, 20,"PROJECT INDEX")
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

          # use full width if the description is displayed
          cols = Array.new(settings.size,1)
          cols.each_with_index{|col,i|
          col = i
          }
          col_width = cols.map {|w| w * (page_width - right_margin - left_margin) / table_width}

          puts "=========#{col_width}======================"
          Project.project_tree(projects) do |project, level|
            project_cells= Array.new
            project_cells<< project.identifier
               if settings.present?
                   Project.column_names.select{|col| settings[col.to_sym] and col!= "identifier" }.each do |column|
                     project_cells<< project[column.to_sym] unless column == "description"
                    end
                  CustomField.where(:type=> "ProjectCustomField").order("name ASC").select{|col| settings[col.name.to_sym] }.each do |cf|
                      project.visible_custom_field_values.select{|coll| coll.custom_field.name == cf.name }.each do |custom_value|
                          unless custom_value.value.blank?
                            project_cells<<   custom_value.value
                           end
                       end
                  end
               end
            puts "=========#{project_cells}======================"
            project_cells.each_with_index do |column, i|
              pdf.RDMCell(45, row_height, column.to_s.strip)
            end
            pdf.ln
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
